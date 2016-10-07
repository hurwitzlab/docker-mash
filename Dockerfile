FROM perl:latest

MAINTAINER Ken Youens-Clark <kyclark@email.arizona.edu>

COPY local /usr/local

COPY scripts /usr/local/bin

RUN ["apt-get", "update", "-y"]

RUN ["apt-get", "install", "gfortran", "libgfortran3", "-y"]

ENV R_LIBS /usr/local/r

ENV PERL5LIB /work/local/lib/perl5

ENTRYPOINT ["run-mash.sh"]
