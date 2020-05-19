$(function () {
    $(document).on('change', '.prioritySelectAll', function () {
        var priorityId = $(this).data('priorityId');
        var kind = $(this).data('kind');

        var checkboxes = $(".intouchPriorityStatusCheckbox[data-priority-id='" + priorityId + "']").filter("input[data-kind='" + kind + "']");
        if ($(this).is(':checked')) {
            checkboxes.prop('checked', true);
        } else {
            checkboxes.prop('checked', false);
        }
    });

    $(document).on('change', '.statusSelectAll', function () {
        var statusId = $(this).data('statusId');
        var kind = $(this).data('kind');

        var checkboxes = $(".intouchPriorityStatusCheckbox[data-status-id='" + statusId + "']").filter("input[data-kind='" + kind + "']");
        if ($(this).is(':checked')) {
            checkboxes.prop('checked', true);
        } else {
            checkboxes.prop('checked', false);
        }
    });

    $('#intouch_settings_settings_template_id').change(function () {
        if ($(this).val() == '') {
            $('.intouch-settings').show()
        } else {
            $('.intouch-settings').hide()
        }
    });
    $('.copyIssueUpdateSettings').click(function () {
        var currentTabContent = $(this).parents('.intouch-tab-content');
        var otherTabContents = currentTabContent.siblings('.intouch-tab-content');

        currentTabContent.find('input[type="checkbox"]:checked').each(function (index, element) {
            otherTabContents.find('input[type="checkbox"].' + $(element).attr('class')).prop('checked', true);
        });

        return false;
    });

    $('.copySettingsFromOtherTab').click(function () {
        var currentTabContent = $(this).parents('.intouch-tab-content');
        var otherTabId = currentTabContent.find('option:selected').val();
        var otherTabContent = $('#intouch-tab-content-' + otherTabId);

        otherTabContent.find('input[type="checkbox"]:checked').each(function (index, element) {
            var priorityId = $(element).data('priorityId');
            var statusId = $(element).data('statusId');
            var protocol = $(element).data('protocol');

            var selector = 'input[type="checkbox"][data-protocol="'+ protocol +'"][data-priority-id="'+ priorityId + '"][data-status-id="'+statusId +'"]';
            currentTabContent.find(selector).prop('checked', true);
        });


        return false;
    });
    $(".accordion").accordion({
        heightStyle: "content",
        activate: displayIntouchTabsButtons,
        beforeActivate: function (event, ui) {
            $('div.tabs-buttons').hide();
        }
    });
});

function showIntouchTab(name) {
    var selectedTab = $('#intouch-tab-' + name);
    var box = selectedTab.parents('.box');
    box.children('.intouch-tab-content').hide();
    box.find('.intouch-tab').removeClass('selected');
    box.children('#intouch-tab-content-' + name).show();
    selectedTab.addClass('selected');

    return false;
}

function displayIntouchTabsButtons() {
    var lis;
    var tabsWidth = 0;
    var el;
    $('div.intouch-tabs').each(function () {
        el = $(this);
        lis = el.find('ul').children();
        lis.each(function () {
            if ($(this).is(':visible')) {
                tabsWidth += $(this).width() + 6;
            }
        });
        if ((tabsWidth < el.width() - 60) && (lis.first().is(':visible'))) {
            el.find('div.tabs-buttons').hide();
        } else {
            el.find('div.tabs-buttons').show();
        }
    });
}
$(document).ready(displayIntouchTabsButtons);
$(window).resize(displayIntouchTabsButtons);

function moveIntouchTabRight(el) {
    var lis = $(el).parents('div.intouch-tabs').first().find('ul').children();
    var tabsWidth = 0;
    var i = 0;
    lis.each(function () {
        if ($(this).is(':visible')) {
            tabsWidth += $(this).width() + 6;
        }
    });
    if (tabsWidth < $(el).parents('div.intouch-tabs').first().width() - 60) {
        return;
    }
    while (i < lis.length && !lis.eq(i).is(':visible')) {
        i++;
    }
    lis.eq(i).hide();
}

function moveIntouchTabLeft(el) {
    var lis = $(el).parents('div.intouch-tabs').first().find('ul').children();
    var i = 0;
    while (i < lis.length && !lis.eq(i).is(':visible')) {
        i++;
    }
    if (i > 0) {
        lis.eq(i - 1).show();
    }
}
