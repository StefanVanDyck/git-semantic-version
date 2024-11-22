FROM bitnami/git:2

COPY version.sh /version.sh

ENTRYPOINT [ "bash", "-c" ]
CMD ["/version.sh", ">>", "$GITHUB_OUTPUT"]