# ediffnw

Addon to Ediff major mode that removes "control buffer" in form of frame or window.
Adds rebinded Ediff keys to variants A, B buffers.

# Activation
1) Execute ```M-x ediffnw RET```
2) ```$ emacs --eval "(ediff \"/file1\" \"/file2\" )"```

# Customization
``` M-x customize-variable RET ediffnw-purge-window RET```
