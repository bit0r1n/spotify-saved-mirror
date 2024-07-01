# Spotify Saved Mirror
A simple tool to mirror saved tracks to public playlist (i.e. make likes public)

## Usage

### Building application
Run `nimble build` command

### Running application
Run `build/mirror_spotify` executable

For automatic update you will need to configure `crontab` (in case of Linux) or something else to run application periodically

### Configuring
In `config.ini` you are able to configure
 * `Spotify.mirror_playlist_id` playlist to mirror
   * ID of playlist or Spotify playlist URI (`spotify:playlist:...`). You can get it from link to playlist. ID is a string with length of ~22 symbols after `/playlist/`
 * `Spotify.ignore_tracks` tracks, that you want to keep in mirror playlist, but are missing in saved tracks
   * List of tracks IDs or Spotify URIs (`spotify:track:...`) separated by commas `,` Getting an ID from link is similar as playlist, but ID is after `/track/`

### Retrieve token (and creating config, you only need to do this once)
First of all, you need to create Spotify Web application for being able to create and update access token

Steps to complete this quest:
1. Go to [Spotify Applications Dashboard](https://developer.spotify.com/dashboard)
2. Click "Create app"
3. Fill fields for name and description as you want
4. Paste `http://localhost:8080` to Redirect URIs and click "Add"
5. Accept the Developer ToS (after reading it, of course!!)
6. Click "Save"
7. You will be redirected to stats page of your application

Now you have an application that will work with this app, but now you need to get access token for your Spotify account

Steps to get first access token:
1. From main/stats page of your Spotify application go to settings by clicking "Settings"
2. Copy "Client ID" and "Client secret" (secret is hidden, click view button)
3. Export client id/secret or paste them as environment variables (`SPOTIFY_ID` and `SPOTIFY_SECRET` respectively) as it acceptable in your shell when you will run auth script
4. Run auth script by executing `build/get_token` It will show link to Spotify authorization page. After you logged in, script will create config with new token

Now that's it, mirror application in further will refresh token by self automatically