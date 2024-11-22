FROM bitnami/git:2


WORKDIR /github/workspace
RUN git config --global --add safe.directory /github/workspace

COPY version.sh /version.sh

ENTRYPOINT [ "bash", "-c" ]
CMD ["/version.sh >> $GITHUB_OUTPUT"]