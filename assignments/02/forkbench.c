#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <sys/wait.h>
#include <unistd.h>
#include <math.h>
#include <string.h>

// The Result struct contains the result of the sum operation and a counter for the number of fork operations.
typedef struct Result {
	int sum;
	int num;
} Result;

// Declare functions to make them usable before the implementation.
Result forkbench(int start, int end);
int parseInt(char *str, char *errMsg);


//convert an int to a string with a trailing newline
char* inttostr(int num) {
    //cannot use floor or log10 since we cannot compile with -lm flag...
    //int charlen = (num <= 9) ? 1 : floor(log10(num)) + 1; //one character for every digit of the int

    //use static values instead
    int charlen;
    if (num <= 9) charlen = 1;
    else if (num <= 99) charlen = 2;
    else if (num <= 999) charlen = 3;
    else if (num <= 9999) charlen = 4;
    else charlen = 10; // i hate this so much

    char *str = malloc(charlen+1); //+1 for newline char
    sprintf(str, "%d\n", num);
    return str;
}

// spawnChild forks a subprocess to compute the sum with the given range of numbers. For computing the sum, the subprocess calls forkbench().
// Before spawning the child process, spawnChild creates a bidirectional pipe. One side of the pipe is returned to the caller,
// the other side is used by the child process to output results.
int spawnChild(int start, int end) {

	// TODO Implement me
    int fd[2]; //write into fd[1], read from fd[0]
    pipe(fd);

	//recursion anchor
	if (start == end) {
        write(fd[1], inttostr(start), strlen(inttostr(start)));
        write(fd[1], "1\n", 2);

        return fd[0]; //return read fd
	}
	pid_t pid = fork();

	if (pid < 0) {// an error occurred
        perror("after fork");
        return -1;

	} else if (pid == 0) { //we're in the child process
        //next recursive call
        Result res = forkbench(start, end);

        //pipe result of forkbench into the fd
        write(fd[1], inttostr(res.sum), strlen(inttostr(res.sum)));
        write(fd[1], inttostr(res.num), strlen(inttostr(res.num)));

        exit(0); //kill this child
        return 0;

	} else if (pid > 0) { //we are the parent
	    wait(0);
	    return fd[0];
	}
}

char * remove_trailing_newline(char* line) {
    char * cleaned_line = malloc(strlen(line));
    sscanf(line,"%s\n", cleaned_line);
    return cleaned_line;
}


// readChild reads data from the given file descriptor and parses it to a Result struct.
// This reads the result data written by a child process in spawnChild().
Result readChild(int fd) {

	// TOD Implement me

	char *line = NULL;
	size_t len = 0;

	size_t line_len;

	char *errMsg = "error in parseInt";
	int sum;
	int num;

	FILE *file  = fdopen(fd, "r");

	//read first line containing res.sum
	if ((line_len = (size_t) getline(&line, &len, file)) != -1) {
        char* cleaned_line = remove_trailing_newline(line);
        sum = parseInt(cleaned_line, errMsg);
        free(cleaned_line);
	}

    //read 2nd line containing res.num
    if ((line_len = getline(&line, &len, file)) != -1) {
        char* cleaned_line = remove_trailing_newline(line);
        num = parseInt(cleaned_line, errMsg);
        free(cleaned_line);
	}

	free(line);

	Result res;
	res.num = num;
	res.sum = sum;

	return res;
}

// forkbench computes the sum of all numbers in the given range (inclusive) by spawning 2 child processes.
// One child computes the sum of the lower range, the other of the upper range.
// The two results are summed and returned.
// If the start and end parameters are equal, the result is returned directly. This is the break condition for the recursion.
Result forkbench(int start, int end) {
	if (start >= end) {
		if (start > end)
			fprintf(stderr, "Start bigger than end: %d - %d\n", start, end);

		// The recursive fork arrived at a leaf process. Return our input and 1 to count this leaf process.
		return (Result) {start, 1};
	}

	// First, spawn child processes for the two sub-ranges. The result is a file descriptor for a buffer where the child will write its results.
	int mid = start + (end - start) / 2;
	int child1 = spawnChild(start, mid);
	int child2 = spawnChild(mid + 1, end);

	// Read the results from the two file descriptors.
	Result res1 = readChild(child1);
	Result res2 = readChild(child2);

	// Wait for the 2 child processes to exit and return the summed result.
	// Add 1 to the number of processes to count the current process.
	wait(0);
	wait(0);
	return (Result) {res1.sum + res2.sum, res1.num + res2.num + 1};
}

// parseInt is a helper function to parse an integer and exit with an error message, if parsing fails.
int parseInt(char *str, char *errMsg) {
	char *endptr = NULL;
	errno = 0;
	int result = strtol(str, &endptr, 10);
	if (errno != 0) {
		perror(errMsg);
		exit(1);
	}
	if (*endptr) {
		fprintf(stderr, "%s: %s\n", errMsg, str);
		exit(1);
	}
	return result;
}

// The main function parses the two command line arguments: The start and end of the number range to sum up.
// Afterwards, it calls forkbench() with the two given parameters.
// After forkbench() completes, the expected result of the sum is computed for validation, using the Gauß sum formula.
// The time for the forkbench() function is measured and the number of forks per second is printed to the standard output.
void main(int argc, char **args) {
	// Parse parameters
	if (argc != 3) {
		fprintf(stderr, "Need 2 parameters: start and end\n");
		exit(1);
	}
	int start = parseInt(args[1], "Failed to parse start argument");
	int end = parseInt(args[2], "Failed to parse end argument");

	// Compute the result using forkbench() and measure the time.
	struct timespec startTime={0,0}, endTime={0,0};
    clock_gettime(CLOCK_MONOTONIC, &startTime);
	Result result = forkbench(start, end);
	clock_gettime(CLOCK_MONOTONIC, &endTime);
	double seconds = ((double) endTime.tv_sec + 1.0e-9*endTime.tv_nsec) - ((double) startTime.tv_sec + 1.0e-9*startTime.tv_nsec);

	// Output the number of forks per second. This is the only output on the stdout.
	printf("%.2f\n", (double) result.num / seconds);
	//printf("num: %d\n", result.num); //mine

	// Compare the result to the expectation and print the result.
	int test = (end*(end+1)/2) - (start*(start+1)/2) + start;
	if (test == result.sum) {
		fprintf(stderr, "Correct result: %d\n", result.sum);
		exit(0);
	} else {
		fprintf(stderr, "Wrong result: %d (should be: %d)\n", result.sum, test);
		exit(1);
	}
}
