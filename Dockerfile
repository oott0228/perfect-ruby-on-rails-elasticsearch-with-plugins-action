FROM docker:stable
RUN apk add --update bash
COPY run-elasticsearch.sh /run-elasticsearch.sh
ENTRYPOINT ["/tun-elasticsearch.sh"]
