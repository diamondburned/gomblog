import Swup from 'https://cdn.jsdelivr.net/npm/swup@3.0/+esm'
import Swupscroll from 'https://cdn.jsdelivr.net/npm/@swup/scroll-plugin@2.0/+esm'
import Swuppreload from 'https://cdn.jsdelivr.net/npm/@swup/preload-plugin@2.0/+esm'

const swup = new Swup({
	containers: [ "main" ],
	animationSelector: 'main',
	plugins: [
		new Swupscroll(),
		new Swuppreload(),
	],
});

// Preload all our articles.
const index = document.getElementById('index');
if (index) {
	const links = index.querySelectorAll('article > a');
	for (const link of links) {
		swup.preloadPage(link.href);
	}
}
