import $ from 'jquery';
import 'bootstrap';
import './flexible.pagination.js'

const animatedElements = [
    ...document.querySelectorAll('svg.icon'),
    ...document.querySelectorAll('ul.video-group li')
];

animatedElements.forEach((el) => {
    el.addEventListener('mouseenter', () => {
        const randomDelay = Math.random() * 30; // random delay up to 30s
        el.style.animationDelay = `-${randomDelay}s`;
    }, { once: true });
});

// From: https://github.com/lay295/TwitchDownloader/blob/d63f861d4cac4d3408fc7a31569cc10e63678ad5/TwitchDownloaderCore/Resources/chat-template.html#L99 (MIT)

/* https://stackoverflow.com/a/63270816 */
const convertColor = (v) => {
    const val = v / 255;
    return val <= 0.03928
        ? val / 12.92
        : Math.pow((val + 0.055) / 1.055, 2.4);
}

const getLuminance = (values) => {
    const r = convertColor(values[0]);
    const g = convertColor(values[1]);
    const b = convertColor(values[2]);

    return Number(0.2126 * r + 0.7152 * g + 0.0722 * b);
};

const getContrastRatio = (lumA, lumB) => {
    return (Math.max(lumA, lumB) + 0.05) / (Math.min(lumA, lumB) + 0.05);
};

const back_color = [255, 255, 255];
const back_luminance = getLuminance(back_color);

if (window.location.pathname !== '/') {
    $('.comment-author').each(function (i, obj) {
        let colorRgb = $(obj).css('color');
        let color = colorRgb.substring(4, colorRgb.length - 1).replace(/ /g, '').split(',');
        if (getContrastRatio(back_luminance, getLuminance(color)) < 1.2) {
            $(obj).css('color', 'black');
        }
    });

    $(function() {
        $('#content').flexiblePagination({
            pagingControlsContainer: "#pagingControls",
            pagingContainer: "#content",
            itemSelector: ".cr:visible",
            itemsPerPageSelector: ".itemPerPageDropDown",
            searchBoxSelector: '.searchBox',
            itemsPerPage: 100,
            currentPage: 1,

            css: {
                btnNumberingClass: "btn btn-sm btn-primary",
                btnActiveClass: "btn btn-sm btn-secondary"
            },
        });
    })
}
