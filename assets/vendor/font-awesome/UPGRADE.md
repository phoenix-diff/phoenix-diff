You are running font-awesome v6.3.0. To upgrade in place, you can run the following command,
where your `FONTAWESOME_VSN` export is your desired version:

    export FONTAWESOME_VSN="6.3.0" ; \
      curl -L "https://github.com/FortAwesome/Font-Awesome/archive/refs/tags/${FONTAWESOME_VSN}.tar.gz" | \
      tar -xvz --strip-components=1 Font-Awesome-${FONTAWESOME_VSN}/svgs

