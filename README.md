# Jacko
Radiant9 Development CLI

#### Purpose
- Site Management.
- Code Sharing Automation.

#### Capabilities
- Create Site
- Build Site
- Bootstrap Site
- Release Site
- Build All Sites
- Release All Sites

#### Commands

##### Launch GUI Interface
```bash
$ jako 
```


##### Create New Site
```bash
$ jako new www.radiant9.com
```

##### Build Site
```bash
$ jako build www.radiant9.com
```

##### Bootstrap Site
```bash
$ jako bootstrap www.radiant9.com --env development
```

##### Publish Site to Heroku
```bash
$ jako publish www.radiant9.com
```

##### Build All Sites
```bash
$ jako build all
```

##### Publish All Sites
```bash
$ jako publish all
```

## Folder Structure

```bash
$ ~/dev/jako
$ ~/dev/jako/blueprints
$ ~/dev/jako/templates

$ ~/dev/gems/ui
$ ~/dev/gems/genesis
$ ~/dev/source/gravity/schematic.yml # move schematics here

$ ~/prod/sources/gravity
$ ~/prod/builds/radiant9_com
$ ~/prod/builds/aniwa_co
```

#### Sources

#### Blueprints
- setup.yml
  * heroku app
  * name
  * url
- schematic.yml
  * heroku addons
  * source map
- env.yml
  * aws (s3)
  * aws (cloudfront)
  * uploadcare
  * segment
  * from_email
  * url

#### Schematics
- Heroku Addons
- Replace Pattern

### Builds

#### APIs
- GitHub
- Heroku
- CodeShip
- AWS (S3)
- AWS (CloudFront)

