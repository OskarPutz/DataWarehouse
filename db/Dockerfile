FROM mcr.microsoft.com/mssql/server:2022-latest

ENV ACCEPT_EULA=Y
ENV MSSQL_SA_PASSWORD=RentMaster_Dev1!

COPY schemas/rentmaster.sql /rentmaster.sql

EXPOSE 1433

CMD /opt/mssql/bin/sqlservr & \
    until /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1; do sleep 2; done; \
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /rentmaster.sql; \
    wait
