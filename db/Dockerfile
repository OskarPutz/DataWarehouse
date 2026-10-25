# RentMaster (SQL Server 2022). The official image is linux/amd64.
# On Apple Silicon, Docker Desktop runs it under emulation.
FROM --platform=linux/amd64 mcr.microsoft.com/mssql/server:2022-latest

USER root
RUN mkdir -p /usr/src/rentmaster
COPY schemas/rentmaster.sql /usr/src/rentmaster/rentmaster.sql
COPY db/entrypoint.sh /usr/src/rentmaster/entrypoint.sh
RUN chmod 755 /usr/src/rentmaster/entrypoint.sh
USER mssql

ENV ACCEPT_EULA=Y \
    MSSQL_PID=Developer \
    MSSQL_SA_PASSWORD=RentMaster_Dev1!

EXPOSE 1433
ENTRYPOINT ["/bin/bash", "/usr/src/rentmaster/entrypoint.sh"]
