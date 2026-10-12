# SEN FileTypes

The FileTypes preference of Haiku with what SEN adds (the source is in the `src/preferences/filetypes` folder of senryu):

- **Searchable** attributes: a checkbox in the dialog of an attribute, which creates (or removes) the index on all volumes when asked, so that the attribute can be queried.
- It opens a type, or one of its attributes, when SEN asks for it (the *Ontologies* menu of the SEN item in the Deskbar).

It has a signature of its own, `application/x-vnd.sen-labs.FileTypes`, and is installed as the preference *SEN FileTypes* beside the one of Haiku. SEN uses it
where it shows a type if it is installed (the setting *Use the FileTypes of SEN* in the Settings of the SEN item, on by default).

```sh
pkgman install sen_filetypes     # from Kiri, https://kiri.sen-labs.org
```

`./package.sh` makes the package from `../bin/FileTypes` (`REVISION=2 ./package.sh` for a new revision).
