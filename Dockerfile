# Use an official Ubuntu runtime as a parent image
FROM ubuntu:latest

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package repository and install SQLite and Gnuplot
RUN apt-get update && \
    apt-get install -y gnuplot python3 curl

# Set the working directory
WORKDIR /app

# Default command to run (not required)
# CMD ["/bin/bash"]