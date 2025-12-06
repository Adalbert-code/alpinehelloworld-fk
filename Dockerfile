# Grab the latest alpine image
FROM alpine:latest

# Install python and pip
RUN apk add --no-cache --update python3 py3-pip bash

# Create a virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies inside the virtual environment
COPY ./webapp/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Add our code
COPY ./webapp /opt/webapp/
WORKDIR /opt/webapp

# Run the image as a non-root user
RUN adduser -D myuser
USER myuser

# Expose port 5000
EXPOSE 5000

# Run the app on port 5000
CMD gunicorn --bind 0.0.0.0:5000 wsgi