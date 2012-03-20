import QtQuick 1.1

/*
Copyright (c) 2011-2012, Vasiliy Sorokin <sorokin.vasiliy@gmail.com>, Aleksey Mikhailichenko <a.v.mich@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of the vsorokin nor the names of its contributors may be used to endorse or
promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


Usage:

    TimePicker {
        id: timePicker
        anchors.centerIn: parent

        function orientationSuffix() {
            if (screen.currentOrientation === Screen.Portrait || screen.currentOrientation === Screen.PortraitInverted )
                return "portrait"
            else
                return "landscape"
        }

        backgroundImage: "image://theme/meegotouch-timepicker-light-1-" + orientationSuffix()
        hourDotImage: "image://theme/meegotouch-timepicker-disc-hours-" + orientationSuffix()
        minutesDotImage: "image://theme/meegotouch-timepicker-disc-minutes-" + orientationSuffix()
    }

Usage for getting a number of minutes with no hours (here up to 6 hours worth of minutes):

    TimePicker {
        id: timePicker
        anchors.centerIn: parent

        function orientationSuffix() {
            if (screen.currentOrientation === Screen.Portrait || screen.currentOrientation === Screen.PortraitInverted )
                return "portrait"
            else
                return "landscape"
        }

        getHours: false
        minuteRounds: 6
        backgroundImage: "image://theme/meegotouch-timepicker-light-1-" + orientationSuffix()
        minutesDotImage: "image://theme/meegotouch-timepicker-disc-minutes-" + orientationSuffix()
    }
*/


Item {
    id: timePicker

    property int hours: 0
    property int minutes: 0

    property bool getHours: true
    property int minuteRounds: 3

    property alias backgroundImage: bg.source
    property alias hourDotImage: hourDot.source
    property alias minutesDotImage: minuteDot.source
    property alias overlayImage: overlay.source

    property int minuteGradDelta: 6
    property int hourGradDelta: 30

    width: bg.sourceSize.width
    height: bg.sourceSize.height

    onHoursChanged: {
        if (hours === 24)
            hours = 0
    }

    onMinutesChanged: {
        if ((getHours && minutes === 60) || minutes === 60 * minuteRounds)
            minutes = 0
    }

    Image {
        id: bg

        anchors.fill: parent

        property int centerX: parent.width / 2
        property int centerY: parent.height / 2

        Image {
            id: overlay
            anchors.centerIn: parent
        }

        Image {
            id: hourDot
            anchors.fill: parent
            rotation: timePicker.hours * 30
            smooth: true
            visible: getHours
        }

        Text {
            id: hourText
            property int hourRadiusX: paintedWidth / 2
            property int hourRadiusY: paintedHeight / 2
            property int hourTrackRadius: parent.width * 0.16

            x: (parent.centerX - hourRadiusX) + hourTrackRadius
               * Math.cos(timePicker.hours * timePicker.hourGradDelta * (Math.PI / 180) - (Math.PI / 2));
            y: (parent.centerY - hourRadiusY) + hourTrackRadius
               * Math.sin(timePicker.hours * timePicker.hourGradDelta * (Math.PI / 180) - (Math.PI / 2));

            font.pixelSize: timePicker.width * 0.09

            text: (timePicker.hours < 10 ? "0" : "") + timePicker.hours
            visible: getHours
        }

        Image {
            id: minuteDot
            anchors.fill: parent
            rotation: timePicker.minutes * 6
            smooth: true
        }

        Text {
            id: minuteText
            property int minuteRadiusX: paintedWidth / 2
            property int minuteRadiusY: paintedHeight / 2
            property int minuteTrackRadius: parent.width * 0.38

            x: parent.centerX - minuteRadiusX + minuteTrackRadius
                * Math.cos(timePicker.minutes * timePicker.minuteGradDelta * (Math.PI / 180) - (Math.PI / 2));
            y: parent.centerY - minuteRadiusY + minuteTrackRadius
                * Math.sin(timePicker.minutes * timePicker.minuteGradDelta * (Math.PI / 180) - (Math.PI / 2));

            font.pixelSize: timePicker.width * 0.09
            color: "#CCCCCC"
            text: ((timePicker.minutes < 10 && getHours) ? "0" : "") + timePicker.minutes
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        property int currentHandler : -1 // 0 - hours, 1 - minutes
        property real previousAlpha: -1

        onPressed: {
            currentHandler = chooseHandler(mouseX, mouseY)
            previousAlpha = findAlpha(mouseX, mouseY)
        }

        onReleased: {
            currentHandler = -1
            previousAlpha = -1
        }

        onPositionChanged: {
            var newAlpha = 0;
            if (currentHandler < 0)
                return

            newAlpha = findAlpha(mouseX, mouseY)

            if (currentHandler > 0) {
                timePicker.minutes = getNewTime(timePicker.minutes, newAlpha, timePicker.minuteGradDelta, (getHours ? 1 : minuteRounds))
            }
            else
                timePicker.hours = getNewTime(timePicker.hours, newAlpha, timePicker.hourGradDelta, 2)
        }

        function sign(number) {
            return  number >= 0 ? 1 : -1;
        }

        function getNewTime(source, alpha, resolution, boundFactor) {
            var delta = alpha - previousAlpha

            if (Math.abs(delta) < resolution)
                return source

            if (Math.abs(delta) > 180) {
                delta = delta - sign(delta) * 360
            }

            var result = source * resolution

            var resdel = Math.round(result + delta)
            if (Math.round(result + delta) > 359 * boundFactor)
                result += delta - 360 * (source * resolution > 359 ? boundFactor : 1)
            else if (Math.round(result + delta) < 0 * boundFactor)
                result += delta + 360 * (source * resolution > 359 ? boundFactor : boundFactor)
            else
                result += delta

            previousAlpha = alpha
            return result / resolution
        }

        function findAlpha(x, y) {

            var alpha = (Math.atan((y - bg.centerY)/(x - bg.centerX)) * 180) / 3.14 + 90
            if (x < bg.centerX)
                alpha += 180

            return alpha
        }

        function chooseHandler(mouseX, mouseY) {
            var radius = Math.sqrt(Math.pow(bg.centerX - mouseX, 2) + Math.pow(bg.centerY - mouseY, 2));
            if (radius <= bg.width * 0.25 && getHours)
                return 0
            else if(radius < bg.width * 0.5)
                return 1
            return -1
        }

    }
}
