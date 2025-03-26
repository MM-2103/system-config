FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4 php7.4-cli php7.4-mbstring php7.4-xml \
    php7.4-curl php7.4-mysql composer git neovim curl unzip

# Create dev user to match your UID (for proper host bind mounts)
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME
