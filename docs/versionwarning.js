(function() {
    // adapted 2022-11 from https://mne.tools/versionwarning.js
    if (location.hostname == 'arrow.apache.org') {
        var latestStable = '10.0.0';
        var pre = '<div class="container-fluid alert-danger devbar"><div class="row no-gutters"><div class="col-12 text-center">';
        var post = '</div></div></div>';
        var anchor = 'class="btn btn-danger font-weight-bold ml-3 my-3 align-baseline"';
        // Switch button message
        var switch_dev = `Switch to unstable development release version`;
        var switch_stable = `latest stable release (version ${latestStable})`;

        var location_array = location.pathname.split('/');
        var versionPath = location_array[2];
        var subPath = location_array[3];
        var filePath = location_array.slice(3).join('/');

        // Links to stable or dev versions
        var uri_dev = `https://arrow.apache.org/docs/dev/${filePath}`;
        var uri_stable = `https://arrow.apache.org/docs/${filePath}`;
        if (versionPath == 'developers') {
            var filePath = location_array.slice(2).join('/');
            var uri_dev = `https://arrow.apache.org/docs/dev/${filePath}`;
            // developers section in the stable version
            var showWarning = `${pre}This is documentation for the stable version ` +
                              `of Apache Arrow (version ${latestStable}). For latest development practices: ` +
                              `<a ${anchor} href=${uri_dev}>${switch_dev} </a>${post}`
            $('.container-fluid').prepend(`${showWarning}`)
        } else if (versionPath.match(/^\d/) < "4") {
            // old versions 1.0,. 2.0 or 3.0
            pre = '<p style="padding: 1em;font-size: 1em;border: 1px solid red;background: pink;">';
            post = '</p>';
            anchor = 'class="btn btn-danger" style="font-weight: bold; vertical-align: baseline;' +
                     'margin: 0.5rem; border-style: solid; border-color: white;"';
            var showWarning = `${pre}This is documentation for an old release of ` +
                              `Apache Arrow (version ${versionPath}). Try the` +
                              `<a ${anchor} href=${uri_stable}>${switch_stable}</a> or` +
                              `<a ${anchor} href=${uri_dev}>development (unstable) version. </a>${post}`
            $('.document').prepend(`${showWarning}`)
        } else if (versionPath.match(/^\d/) && subPath == 'developers') {
            // older versions of developers section (with numbered version in the URL)
            var showWarning = `${pre}This is documentation for an old release of Apache Arrow ` +
                              `(version ${versionPath}). For latest development practices: ` +
                              `<a ${anchor} href=${uri_dev}>${switch_dev} </a>${post}`
            $('.container-fluid').prepend(`${showWarning}`)
        } else if (versionPath.match(/^\d/)) {
            // older versions (with numbered version in the URL)
            var showWarning = `${pre}This is documentation for an old release of ` +
                              `Apache Arrow (version ${versionPath}). Try the` +
                              `<a ${anchor} href=${uri_stable}>${switch_stable}</a> or` +
                              `<a ${anchor} href=${uri_dev}>development (unstable) version. </a>${post}`
            $('.container-fluid').prepend(`${showWarning}`)
        }
    }
})()
