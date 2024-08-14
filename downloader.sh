#!/bin/bash

UserAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"

# Get Latest Stable Version Of Snapchat
page1=$(curl --fail-early --connect-timeout 2 --max-time 5 -sL -A "$UserAgent" "https://www.apkmirror.com/uploads/?appcategory=Snapchat" 2>&1)
readarray -t versions < <(pup -p 'div.widget_appmanager_recentpostswidget h5 a.fontBlack text{}' <<<"$page1")

for version in "${versions[@]}"; do
    if [[ ! "$version" == *"Beta" ]] && [[ ! "$version" == *"beta" ]]; then
        # Extract version number and replace spaces with hyphens
        version=$(echo "$version" | tr ' ' '-' | tr '.' '.' | tr '[:upper:]' '[:upper:]')
        echo "$version"
        echo "VERSION=$version" >> $GITHUB_ENV

        # Extract version and removes Snapchat and replaces the hyphen with a v
        shortversion=$(echo "$version" | tr -d 'Snapchat' | tr '-' 'v')
        echo "SHORTVERSION=$shortversion" >> $GITHUB_ENV

        # Direct link for APK file
        apkmirror_link="https://www.apkmirror.com/apk/snap-inc/snapchat/$version-release"

        page1=$(curl -vsL -A "$UserAgent" "$apkmirror_link" 2>&1)

        canonicalUrl=$(pup -p --charset utf-8 'link[rel="canonical"] attr{href}' <<<"$page1")
        if [[ "$canonicalUrl" == *"apk-download"* ]]; then
            url1=("${canonicalUrl/"https://www.apkmirror.com/"//}")
        else
            grep -q 'class="error404"' <<<"$page1" && continue

            page2=$(pup -p --charset utf-8 ':parent-of(:parent-of(span:contains("APK")))' <<<"$page1")

            [[ "$(pup -p --charset utf-8 ':parent-of(div:contains("noarch"))' <<<"$page2")" == "" ]] || arch=noarch
            [[ "$(pup -p --charset utf-8 ':parent-of(div:contains("universal"))' <<<"$page2")" == "" ]] || arch=universal

            readarray -t url1 < <(pup -p --charset utf-8 ":parent-of(div:contains(\"$arch\")) a.accent_color attr{href}" <<<"$page2")

            [ "${#url1[@]}" -eq 0 ] && continue
        fi
        echo 33

        url2=$(curl -sL -A "$UserAgent" "https://www.apkmirror.com${url1[-1]}" | pup -p --charset utf-8 'a:contains("Download APK") attr{href}')

        [ "$url2" == "" ] && continue
        echo 66

        url3=$(curl -sL -A "$UserAgent" "https://www.apkmirror.com$url2" | pup -p --charset UTF-8 'a[data-google-interstitial="false"][rel="nofollow"] attr{href}')

        [ "$url3" == "" ] && continue
        echo 100

        echo "https://www.apkmirror.com$url3" >&2
        echo "Downloading APK from: https://www.apkmirror.com$url3"

        # Downloads the snapchat APK file and save it as snapchat.apk
        wget -U "$UserAgent" -O snapchat.apk "https://www.apkmirror.com$url3"
        if [ $? -eq 0 ]; then
            echo "Snapchat APK Downloaded successfully and is renamed to snapchat.apk"
            exit 0
        else
            echo "Failed To Download Snapchat APK" >&2
            exit 1
        fi
    fi
done

echo "No suitable version found."
exit 1