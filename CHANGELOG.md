# Changelog

What changed in each version. The newest version is at the top.
In the VM you get the latest version with the **Update** button in the Lab Trainer.

## Beta 0.5 – 25.11.2026
- **New:** everything is in **English** now: Lab Trainer, all 15 labs, documents, README.
  The files you create in the labs now have English names (e.g. `notes.md`, `users.csv`). Labs started with an older version may need to be started again.
- **Fixed:** Lab 5 and Lab 13 accept Markdown bold and tables. Lab 13 accepts extra text after a value (e.g. `10.20.30.0/23`) and no longer passes if a question is answered twice.
- **Fixed:** Lab 10 accepts VMware Tools, "print server", "fixed IP" and similar wording.
- **Fixed:** Lab 15 ignores block comments `<# #>` in the script.
- **Fixed:** "Create doc" reads files saved as UTF-8 without BOM correctly.
- **Fixed:** the PC shortcut is created even if the VM does not start; the ISO window opens in front; an ISO that is already mounted works.
- **Fixed:** the Lab Trainer window can no longer be made so small that buttons overlap.
- README: Broadcom terms, open VMware once, logon after the restart, what the PC shortcut is for.

## Beta 0.4 – 25.11.2026
- **Fixed:** Lab 15 accepts names even if the CSV was saved without UTF-8 (umlauts). Comments no longer count as a script.
- **Fixed:** Lab 14 also checks the right of each line; wrong extra lines are detected. Abbreviations are allowed.
- **Fixed:** Lab 13 accepts Markdown bold. Lab 10 recognises "4096 MB" and "255.255.255.192" and has hints.
- **Fixed:** the first click on "Update" always reported "new".
- **Fixed:** leftovers of an old version could bring old documents into the VM.
- **Fixed:** START.cmd asks first and only copies afterwards. There is now a PC shortcut.
- The self-test leaves a real Lab 12 task alone.
- Clearer licence: use in apprenticeships, vocational school and courses is allowed.
- README: Broadcom steps, keep the ISO, inner folder, open the VM again, keyboard.

## Beta 0.3 – 25.11.2026
- **Fixed:** the installation now works with a Windows ISO in any language. Language and edition are read from the ISO.
- **Fixed:** the quiz and labs 10, 13, 14 and 15 work for everyone. Flashcards and scenario data are now in `Unterlagen/`.
- **Fixed:** "Reset VM" offers to create the snapshot if there is none yet.
- **Fixed:** buttons in the Lab Trainer overlapped.
- **Fixed:** VMware is also found in a different installation folder.
- **Fixed:** Lab 14 accepts CSV with ";" and without UTF-8; Lab 15 also checks names and the script.
- **Fixed:** START.cmd reports if the ZIP file is not extracted. A failed VM start is reported.
- **Update** now also gets the documents.
- README: system requirements, Broadcom account, which ISO, snapshot tip.

## Beta 0.2 – 25.11.2026
- **New:** **Update** button in the Lab Trainer gets the latest labs from GitHub (with check and backup)
- **New:** version number in the Lab Trainer
- **New:** self-test for all 15 labs (`Tests/selbsttest.ps1`), runs automatically on GitHub with every push
- **New:** forms for bugs and ideas under *Issues*
- **Fixed:** Lab 5 crashed with some network adapters

## Beta 0.1 – 25.11.2026
- 15 labs with automatic checks
- Lab Trainer with doc helper and quiz
- One-click installation with `START.cmd`
- Licence: use allowed, copying and selling not
