1. docker pull golang
2. `%cd%` 是当前目录, -v 意思是挂载 当前目录 与 docker /go/downloads/ 目录同步
  - docker run --rm -it -v %cd%:/go/downloads/ -w /usr/src/myapp golang bash
  - `docker run --rm -it -v %cd%:/go/downloads/ golang bash`
3. https://github.com/winterssy/mxget 根据步骤执行命令
`go get -u github.com/winterssy/mxget`
`mxget song --from nc --id 36990266`
4. `cp -a  go/downloads/. /myapp/`  下载到本地