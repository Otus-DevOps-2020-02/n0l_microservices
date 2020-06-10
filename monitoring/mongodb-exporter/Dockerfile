# решение подсказали коллеги, на мой взгляд гораздо более красивое, чем скрипт на bash, хотя результат одинаковый)
FROM golang:1.11

# для того чтобы не копировать исходники в репозиторий используем образ golang:1.11 для сборки билда
WORKDIR /go/src/github.com/percona/mongodb_exporter
RUN git clone https://github.com/percona/mongodb_exporter.git && mv mongodb_exporter/* . && make build

# используем busybox для запуска mongodb_exporter
# https://github.com/coreos/prometheus-operator/issues/2909
FROM quay.io/prometheus/busybox:latest
COPY --from=0 /go/src/github.com/percona/mongodb_exporter/bin/mongodb_exporter /bin/mongodb_exporter

EXPOSE 9216

ENTRYPOINT [ "/bin/mongodb_exporter" ]

