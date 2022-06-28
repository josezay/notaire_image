#include "sys/stat.h"
#include "sys/utime.h"
#include "time.h"
#include "stdio.h"

int main(int argc, char* argv[])
{
	struct stat foo;
	time_t mtime;
	struct utimbuf new_times;
	printf("%s", argv[1]);

	stat(argv[1], &foo);
	mtime = foo.st_mtime; /* seconds since the epoch */

	new_times.actime = foo.st_atime; /* keep atime unchanged */
	new_times.modtime = time(NULL);    /* set mtime to current time */
	utime(argv[1], &new_times);

	getchar();

	return 0;
}
