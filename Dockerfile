FROM python:3.10.14

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo
RUN echo $TZ > /etc/timezone

# Change default shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN chsh -s /bin/bash

# タイムゾーンを設定
RUN apt update && apt install -y tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo "Asia/Tokyo" > /etc/timezone

# Configure apt and install packages
ARG DEV_PACKAGES="unzip make curl tzdata screen peco git vim openssh-server iproute2 iputils-ping net-tools dnsutils tree"
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ${DEV_PACKAGES}\
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Node.jsをインストール
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@latest

# pnpmをnインストール
RUN npm install -g pnpm

# uvをインストール
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install python packages
WORKDIR /setup
# COPY ./pyproject.toml ./poetry.lock ./
RUN pip install -U pip \
    && pip install poetry\
    && poetry config virtualenvs.create false
# RUN poetry install --no-root

# PostgresSQLをインストール
RUN apt-get update \
    && apt-get install -y postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Terminal setting
RUN wget --progress=dot:giga https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O ~/.git-completion.bash \
    && wget --progress=dot:giga https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -O ~/.git-prompt.sh \
    && chmod a+x ~/.git-completion.bash \
    && chmod a+x ~/.git-prompt.sh \
    && echo -e "\n\
    source ~/.git-completion.bash\n\
    source ~/.git-prompt.sh\n\
    export PS1='\\[\\e[30m\\]\\\\t\\[\\e[0m\\] \\[\\e]0;\\u@\\h: \\w\\a\\]\${debian_chroot:+($debian_chroot)}\\[\\033[01;32m\\]\\u\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\[\\033[1;30m\\]\$(__git_ps1)\\[\\033[00m\\]\\$ '\n\
    " >> ~/.bashrc

WORKDIR /project

ENV SHELL=/bin/bash