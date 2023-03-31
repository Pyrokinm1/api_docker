FROM dart:2.18.6-sdk


WORKDIR /app
COPY pubspec.* ./
RUN dart pub get


COPY . .

RUN dart pub get

RUN dart pub global activate conduit 4.1.6

EXPOSE 8888


ENTRYPOINT  ["dart","run","/app/bin/pr_api.dart","conduit:conduit"]
