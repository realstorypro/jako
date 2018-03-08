# Jacko
Radiant9 Development CLI

#### Purpose
- Site Management.
- Code Sharing Automation.

#### Capabilities
- Create Site
- Build Site
- Update Site
- Update All Sites *(Coming Soon)*

#### Commands

##### Launch GUI Interface
```bash
$ ./bin/jako 
```


## Folder Structure

Jacko is located here
```bash
$ ~/dev/jako
```

Schematics used by jako are located here
```bash
$ ~/dev/jako/schematics
```

Templates for jako are located here
```bash
$ ~/dev/jako/templates
```

Blueprints are stored here. They're source controlled.
```bash
$ ~/dev/blueprints 
```

Builds are stored here. They're not source controlled.
```bash
$ ~/dev/builds // where the builds live
```

Sources are stored here.
```bash
$ ~/dev/sources
```

#### Sources

#### Blueprints
- setup.yml - automatically generated
- env.yml - needs to be manually populated
- **files** folder is located here. They contents of the folder are copied
to the build folder for the blueprint.

#### Schematics
- Source Folder
- Replace Pattern for URL and Name
- Heroku Addons

