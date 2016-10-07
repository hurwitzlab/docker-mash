# Docker Mash

This is a Docker container to run the Fizkin/Mash pairwise comparison.

Copy the "mash" binary into "local/bin."

To build it, I brought up the container in interactive mode and
installed the needed Perl and R modules (and R itself) into
"/work/local/..." and then did "make image" to copy the installed
modules into the image.  This seemed easier than any other way I could
manage to build the image.  Waiting for Docker to install everything
from the Dockerfile takes way too long.

# Author

Ken Youens-Clark <kyclark@email.arizona.edu>
