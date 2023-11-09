FROM ubuntu:20.04
SHELL [ "/bin/bash", "-c" ]
RUN apt update && apt install -y git build-essential jq wget

# Install and setup GO
RUN wget https://go.dev/dl/go1.21.4.linux-amd64.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
# Ensure go was installed successfully
RUN go version

# Build Nyx
RUN git clone https://github.com/nymtech/nyxd.git
WORKDIR /nyxd
RUN git checkout release/v0.43.0
RUN make build
ENV PATH=$PATH:/nyxd/build
# Check Nyx installation
RUN nyxd

# Initialise and Start validator
COPY init_and_start.sh .
ENTRYPOINT [ "./init_and_start.sh" ]
