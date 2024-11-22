FROM bitnami/git:2


COPY version.sh /version.sh

USER 1001
WORKDIR /github/workspace
ENTRYPOINT [ "bash", "-c" ]
CMD ["/version.sh >> $GITHUB_OUTPUT"]