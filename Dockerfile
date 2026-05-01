FROM ixpantia/faucet:r4.4

WORKDIR /home/faucet

RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    curl \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/lib/R/etc && \
    echo "options(repos = c(CRAN = 'https://p3m.dev/cran/__linux__/jammy/latest', duckdb = 'https://duckdb.r-universe.dev'))" >> /usr/local/lib/R/etc/Rprofile.site

RUN R -e "install.packages('pak', repos='https://cloud.r-project.org/')"

RUN R -e "pak::pkg_install(c('data.table', 'httr', 'jsonlite', 'jose', 'openssl', 'rmarkdown', 'tinytest', 'plotly', 'htmltools', 'htmlwidgets', 'flexdashboard', 'DBI', 'duckdb', 'reactable', 'echarts4r', 'shiny', 'bslib'))"

COPY rpkgs/bfett/ /tmp/bfett/
RUN R -e "pak::local_install('/tmp/bfett', dependencies = FALSE)"

RUN python3 -m venv /opt/lea-venv
RUN /opt/lea-venv/bin/pip install --upgrade pip
RUN /opt/lea-venv/bin/pip install lea-cli duckdb
ENV PATH="/opt/lea-venv/bin:${PATH}"

COPY dashboard/app.R /home/faucet/dashboard/app.R
COPY dashboard/rpkgs/ /home/faucet/rpkgs/
COPY ingest/ /home/faucet/ingest/
COPY transform/ /home/faucet/transform/
COPY Makefile /home/faucet/Makefile

RUN chown -R faucet:faucet /home/faucet/

USER faucet

EXPOSE 3838
CMD ["faucet", "start", "--dir", "/home/faucet/dashboard"]