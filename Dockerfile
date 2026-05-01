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

## R Configuration (Using PPM Binaries)
COPY rpkgs/bfett/ /tmp/bfett/
RUN R_VERSION=$(R --version | head -n 1 | sed -E 's/.*version ([0-9]+\.[0-9]+).*/\1/') && \
    echo "Detected R version: $R_VERSION" && \
	mkdir -p /usr/lib/R/etc && \
    echo "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/noble/latest'), pkg.type = 'binary')" >> /usr/lib/R/etc/Rprofile.site && \
    echo "" >> /usr/lib/R/etc/Rprofile.site && \
    echo "# Custom q() that does not ask to save workspace by default" >> /usr/lib/R/etc/Rprofile.site && \
    echo "utils::assignInNamespace(" >> /usr/lib/R/etc/Rprofile.site && \
    echo "  'q'," >> /usr/lib/R/etc/Rprofile.site && \
    echo "  function(save = 'no', status = 0, runLast = TRUE) {" >> /usr/lib/R/etc/Rprofile.site && \
    echo "    .Internal(quit(save, status, runLast))" >> /usr/lib/R/etc/Rprofile.site && \
    echo "  }," >> /usr/lib/R/etc/Rprofile.site && \
    echo "  'base'" >> /usr/lib/R/etc/Rprofile.site && \
    echo ")" >> /usr/lib/R/etc/Rprofile.site && \
    R -q -e 'install.packages("pak", repos = "https://r-lib.github.io/p/pak/stable")' && \
    R -q -e 'pak::pkg_install(c("remotes", "data.table", "duckdb", "shiny", "bslib", "reactable", "plotly", "pdftools", \
		  "RhpcBLASctl", "nanoparquet", "httr", "jsonlite", "R.utils", \
      "httr", "jsonlite", "jose", "openssl", "rmarkdown", "tinytest", "plotly", "htmltools", "htmlwidgets", "echarts4r")' && \
    R -q -e "pak::local_install('/tmp/bfett', dependencies = FALSE)"
        
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
