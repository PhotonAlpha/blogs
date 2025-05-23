# gradle 作用于多模块build配置

### 父类 build.gradle
父类添加

    dependencies {
      classpath "org.springframework.boot:spring-boot-gradle-plugin:${springBootVersion}"
    }
### 子模块 build.gradle
使用

    apply plugin: 'org.springframework.boot' //使用springboot插件
    jar {
      baseName = 'batch'
      version = '1.0.0'
    }


### 参考
```
buildscript {
    ext {
        springBootVersion = '2.3.7.RELEASE'
        springCloudVersion = 'Hoxton.SR9'
    }

    repositories {
        // 本地maven仓库
        mavenLocal()
//        maven { url = 'http://maven.aliyun.com/nexus/content/groups/public/' }
        mavenCentral()
//        maven { url = 'http://jaspersoft.jfrog.io/jaspersoft/third-party-ce-artifacts/' }
        //和maven中央仓库一样的另一个依赖管理仓库,主要是java
        jcenter()
    }

    dependencies {
        classpath "org.springframework.boot:spring-boot-gradle-plugin:${springBootVersion}"
    }
}

allprojects {
    tasks.withType(JavaCompile) {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    group = 'com.ethan'
    version = '1.0.0'
}

subprojects {
//    apply plugin: 'java'
    apply plugin: 'idea'
    apply plugin: 'org.springframework.boot' //使用springboot插件
    apply plugin: 'io.spring.dependency-management' //版本管理插件
    apply plugin: 'application' // 识别mainClassName 插件

//    如果是多模块项目,需要指定一个程序入口,必须指定,否则无法build,单模块可以不用指定
//    mainClassName = 'cm.hou.blogweb.BlogWebApplication'
//     java编译的时候缺省状态下会因为中文字符而失败
    [compileJava, compileTestJava, javadoc]*.options*.encoding = 'UTF-8'

    repositories {
        // 本地maven仓库
        mavenLocal()
//        maven { url = 'http://maven.aliyun.com/nexus/content/groups/public/' }
        mavenCentral()
//        maven { url = 'http://jaspersoft.jfrog.io/jaspersoft/third-party-ce-artifacts/' }
        //和maven中央仓库一样的另一个依赖管理仓库,主要是java
        jcenter()
    }

    dependencyManagement {
        imports {
            mavenBom "org.springframework.cloud:spring-cloud-dependencies:${springCloudVersion}"
        }
    }

    dependencies {
        compileOnly 'org.projectlombok:lombok:1.18.16'
        annotationProcessor 'org.projectlombok:lombok:1.18.16'

        testImplementation 'org.projectlombok:lombok:1.18.16'

        testImplementation('org.springframework.boot:spring-boot-starter-test') {
            // exclude junit 4 https://stackoverflow.com/questions/59900637/error-testengine-with-id-junit-vintage-failed-to-discover-tests-with-spring
            exclude group: 'junit', module: 'junit'
            exclude group: 'org.junit.vintage', module: 'junit-vintage-engine'
        }

        testImplementation 'org.junit.jupiter:junit-jupiter-api:5.6.3'
//        testImplementation 'org.junit.jupiter:junit-jupiter-params:5.6.3'
        testRuntimeOnly  'org.junit.jupiter:junit-jupiter-engine:5.6.3'
    }
    test {
        useJUnitPlatform()
    }
}
```