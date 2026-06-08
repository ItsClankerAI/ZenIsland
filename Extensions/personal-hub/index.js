"use strict";

var App = (typeof ZenBar !== "undefined") ? ZenBar : SuperIsland;
var lastTick = Date.now();

function pad(value) {
  return value < 10 ? "0" + value : String(value);
}

function timeLabel() {
  var now = new Date();
  var hours = now.getHours();
  var minutes = pad(now.getMinutes());
  var suffix = hours >= 12 ? "PM" : "AM";
  var displayHour = hours % 12;
  if (displayHour === 0) displayHour = 12;
  return displayHour + ":" + minutes + " " + suffix;
}

function dateLabel() {
  var now = new Date();
  return now.toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric"
  });
}

function greeting() {
  var hour = new Date().getHours();
  if (hour < 12) return "Morning";
  if (hour < 17) return "Afternoon";
  return "Evening";
}

function primaryURL() {
  return App.settings.get("primaryURL") || "https://calendar.google.com";
}

function secondaryURL() {
  return App.settings.get("secondaryURL") || "https://music.apple.com";
}

function mediaSnapshot() {
  var snapshot = App.system.getNowPlaying();
  if (!snapshot || !snapshot.title) {
    return {
      title: "No media playing",
      subtitle: "Calendar, shelf, and battery are ready",
      isPlaying: false
    };
  }

  var artist = snapshot.artist || snapshot.sourceApp || "Media";
  return {
    title: snapshot.title,
    subtitle: artist,
    isPlaying: snapshot.playbackState === "playing"
  };
}

function statusColor() {
  var hour = new Date().getHours();
  if (hour < 12) return "cyan";
  if (hour < 17) return "blue";
  return "purple";
}

function renderCompact() {
  var media = mediaSnapshot();
  return View.hstack([
    View.icon(media.isPlaying ? "music.note" : "sparkles", { color: statusColor(), size: 13 }),
    View.text(timeLabel(), { style: "monospacedSmall", color: "white" }),
    View.text(media.isPlaying ? "Playing" : greeting(), { style: "caption", color: "gray", lineLimit: 1 })
  ], { spacing: 6, align: "center" });
}

function renderExpanded() {
  var media = mediaSnapshot();
  return View.vstack([
    View.hstack([
      View.vstack([
        View.text(greeting() + " - " + timeLabel(), { style: "title", color: "white", lineLimit: 1 }),
        View.text(dateLabel(), { style: "caption", color: "gray", lineLimit: 1 })
      ], { spacing: 2, align: "leading" }),
      View.spacer(),
      View.icon("sparkles", { color: statusColor(), size: 20 })
    ], { spacing: 8, align: "center" }),
    View.hstack([
      View.icon(media.isPlaying ? "music.note" : "music.note.list", { color: media.isPlaying ? "green" : "gray", size: 13 }),
      View.marqueeText(media.title, { style: "body", color: "white" }),
      View.text(media.subtitle, { style: "caption", color: "gray", lineLimit: 1 })
    ], { spacing: 7, align: "center" }),
    View.hstack([
      View.button(View.text("Calendar", { style: "caption" }), "open-primary"),
      View.button(View.text("Music", { style: "caption" }), "open-secondary"),
      View.button(View.text("Refresh", { style: "caption" }), "refresh")
    ], { spacing: 8, align: "center" })
  ], { spacing: 7, align: "leading" });
}

function renderFullExpanded() {
  var media = mediaSnapshot();
  return View.vstack([
    View.hstack([
      View.icon("sparkles", { color: statusColor(), size: 24 }),
      View.vstack([
        View.text("Personal Hub", { style: "largeTitle", color: "white", lineLimit: 1 }),
        View.text(greeting() + " - " + dateLabel() + " - " + timeLabel(), { style: "subtitle", color: "gray", lineLimit: 1 })
      ], { spacing: 2, align: "leading" }),
      View.spacer()
    ], { spacing: 12, align: "center" }),
    View.divider(),
    View.hstack([
      View.vstack([
        View.text("Now Playing", { style: "headline", color: "white" }),
        View.marqueeText(media.title, { style: "body", color: "white" }),
        View.text(media.subtitle, { style: "caption", color: "gray", lineLimit: 1 })
      ], { spacing: 4, align: "leading" }),
      View.spacer(),
      View.vstack([
        View.button(View.text("Open Calendar", { style: "body" }), "open-primary"),
        View.button(View.text("Open Music", { style: "body" }), "open-secondary")
      ], { spacing: 8, align: "trailing" })
    ], { spacing: 18, align: "center" }),
    View.text("Practical widgets enabled: Now Playing, Battery, Calendar, and File Shelf.", { style: "caption", color: "gray", lineLimit: 1 })
  ], { spacing: 12, align: "leading" });
}

function openURL(url) {
  if (typeof url === "string" && url.length > 0) {
    App.openURL(url);
  }
}

function refresh() {
  lastTick = Date.now();
}

App.registerModule({
  compact: renderCompact,
  expanded: renderExpanded,
  fullExpanded: renderFullExpanded,
  minimalCompact: {
    precedence: 2,
    leading: function () {
      return View.hstack([
        View.icon("sparkles", { color: statusColor(), size: 12 }),
        View.text(timeLabel(), { style: "monospacedSmall", color: "white" })
      ], { spacing: 5, align: "center" });
    },
    trailing: function () {
      var media = mediaSnapshot();
      return View.icon(media.isPlaying ? "music.note" : "calendar", {
        color: media.isPlaying ? "green" : "gray",
        size: 13
      });
    }
  },
  onActivate: refresh,
  onAction: function (actionID) {
    if (actionID === "open-primary") {
      openURL(primaryURL());
    } else if (actionID === "open-secondary") {
      openURL(secondaryURL());
    } else if (actionID === "refresh") {
      refresh();
      App.playFeedback("selection");
    }
  }
});
