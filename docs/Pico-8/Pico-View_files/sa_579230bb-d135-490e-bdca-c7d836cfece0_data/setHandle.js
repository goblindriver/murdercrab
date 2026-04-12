$(document).ready(function () {
    // Trigger validation on document ready in case input is empty
    var handleInputElement = $("#Handle");
    if (handleInputElement) {
        toggleValidationMessagesFor(handleInputElement);
    }
});

$(document).on("keypress",
    "#handle,#Handle",
    function (event) {
        return preventUnwantedCharactersInUsername(event);
    });

$(document).on("keyup",
    "#handle,#Handle",
    function (event) {
        toggleValidationMessagesFor(event.target);
        toggleClaimHandleButtonEnabled(event.target, "#claimHandleButton");
    });

window.addEventListener("creatorBecameAContributor", function creatorBecameAContributor(e) {
    if (e.detail.action === "settings-short-handle") {
        var btn = $("#claimHandleButton");
        btn.removeClass("js-required-fees-opt-in-controls js-trigger-short-handle-contributor-modal");
        claimHandle();
    }
}, false);

function claimHandle() {
    var btn = $("#claimHandleButton");
    var handle = $("#handle").val();

    if (btn.hasClass("js-required-fees-opt-in-controls") && handle.length < 5) {
        // Clicking the button will trigger contributor opt-in
        return;
    }

    btn.addClass("disabled");
    $.ajax({
        type: "POST",
        ajaxasync: true,
        data: { handle: handle },
        url: "/Manage/ClaimHandle/",
        success: function (response) {
            if (response && response.success === false) {
                toastr.error(response.friendly_error_message || "That handle is unavailable");
                $("#claimHandleButton").removeClass("disabled");
                return;
            }
            toastr.success("Ko-fi.com/" + handle, "Username Updated");
            $("#claimHandleButton").addClass("disabled");
            $("#handleModal").modal('toggle');
            $("#linkAddress").html("ko-fi.com/" + handle);
            $("#linkAddress").attr("href", "/" + handle);
            if ($("#profileModal")) {
                $("#profileModal").modal();
            }

        },
        error: function () {
            toastr.error("That handle is unavailable");
            $("#claimHandleButton").removeClass("disabled");
        }
    });
}

function claimHandleOnboarding() {
    var errors = $(".field-validation-error");
    if (errors.length > 0) {
        toastr.error("Your Username should be a minimum of 5 characters (a-z, 0-9).");
        $("#claimHandleButton").removeClass("disabled");
        return;
    }

    $("#claimHandleButton").addClass("disabled");
    var handle = $("#Handle").val();
    $.ajax({
        type: "POST",
        ajaxasync: true,
        data: { handle: handle },
        url: "/Manage/ClaimHandle/",
        success: function (response) {
            if (response && response.success === false) {
                toastr.error(response.friendly_error_message || "That handle is unavailable");
                $("#claimHandleButton").removeClass("disabled");
                return;
            }
            showSpinner();
            window.location.href = "/Account/OnboardingUploadAvatar";
            $("#claimHandleButton").removeClass("disabled");

        },
        error: function () {
            toastr.error("That handle is unavailable");
            $("#claimHandleButton").removeClass("disabled");
        }
    });
}

function preventUnwantedCharactersInUsername(event) {
    var regex = new RegExp("^[a-zA-Z0-9_]*$");
    var key = String.fromCharCode(!event.charCode ? event.which : event.charCode);

    if (!regex.test(key)) {
        if (event.key === "Backspace" || event.key === "ArrowLeft" || event.key === "ArrowRight" || event.key === "Delete") { // Left / Up / Right / Down Arrow, Backspace, Delete keys

            return;
        }
        event.preventDefault();
        return false;
    }
}

function toggleClaimHandleButtonEnabled(input, buttonSelector) {
    var inputElement = $(input);
    var buttonElement = $(buttonSelector);

    if (!inputElement || !buttonElement) {
        return;
    }

    // With contributor prompt in place this should always be 3
    var minCharactersToTriggerDisabled = 3;// inputElement.attr("data-min-characters");
    //if (!minCharactersToTriggerDisabled && minCharactersToTriggerDisabled !== 0)
    //    minCharactersToTriggerDisabled = 3;//Defaults to 3, as it was originally
    var handleLength = inputElement.val().length;
    if (handleLength < 3)
    {
        buttonElement.addClass("disabled");
    } else if (handleLength < minCharactersToTriggerDisabled) {
        // If we can prompt to become a contributor, don't disable
        if (!buttonElement.hasClass("js-required-fees-opt-in-controls"))
            buttonElement.addClass("disabled");
    } else {
        buttonElement.removeClass("disabled");
    }
}

function toggleValidationMessagesFor(input) {
    var inputElement = $(input);
    if (!inputElement) {
        return;
    }

    var inputId = inputElement.attr("id");
    if (inputId !== "Handle") {
        return;
    }

    var thisInputValidationContainer = inputElement.closest(".js-validation-container").find("[data-valmsg-for='" + inputId + "']");
    if (!thisInputValidationContainer) {
        return;
    }

    var minLengthErrorMessageElement = thisInputValidationContainer.find(".error-min-length");
    var requiredErrorMessageElement = thisInputValidationContainer.find(".error-required");

    var minCharactersToTriggerDisabled = inputElement.attr("data-min-characters");
    if (!minCharactersToTriggerDisabled && minCharactersToTriggerDisabled !== 0)
        minCharactersToTriggerDisabled = 3;//Defaults to 3, as it was originally

    if (inputElement.val().length < minCharactersToTriggerDisabled) {
        thisInputValidationContainer.addClass("field-validation-error");
        thisInputValidationContainer.removeClass("field-validation-valid");

        if (inputElement.val().length === 0) {
            requiredErrorMessageElement.show();
            minLengthErrorMessageElement.hide();
        }
        else {
            requiredErrorMessageElement.hide();
            minLengthErrorMessageElement.show();
        }
    } else {
        thisInputValidationContainer.removeClass("field-validation-error");
        thisInputValidationContainer.addClass("field-validation-valid");
        requiredErrorMessageElement.hide();
        minLengthErrorMessageElement.hide();
    }
}