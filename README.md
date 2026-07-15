# Phone Link Bluetooth Doctor — TCDOVERLORD

Consent-first Windows Phone Link Bluetooth call diagnostics and repair.

## Run the Doctor

Right-click `RUN_PHONE_LINK_DOCTOR.bat` and choose **Run as administrator** if Windows requests administrator permission.

## Final menu

1. Run diagnostics only  
2. Choose or change speaker, microphone, and Bluetooth phone  
3. Configure Windows call speaker and microphone  
4. Run diagnostics, review, then offer safe Phone Link repair  
5. Reset Doctor selections and run setup again  
6. Open newest log folder  
7. Exit  

## Important

The selected microphone and speaker must be set in Windows as both:

- Default Device
- Default Communication Device

Menu option 3 opens the correct Windows Playback and Recording panels and guides the user through this.

## After a repair

When the repair finishes, the Doctor displays a large restart message. Restart the computer before testing Phone Link again.

Type `EXIT` at the final prompt to close Phone Link Bluetooth Doctor, then restart Windows normally.

## Safety

The tool does not remove, uninstall, forget, unpair, or delete devices. It does not force-kill the Bluetooth Audio Gateway `svchost.exe`. If that service becomes stuck in `STOP_PENDING`, the tool requires a normal Windows restart.

## Optional script signing

The included launcher does not require a separate signed-launcher file. Users who maintain their own PowerShell signing setup may sign the `.ps1` files themselves.
