import { Page, Locator, expect } from '@playwright/test';

/**
 * Highlights a locator with a dark overlay and a yellow border.
 * If a description is provided, it shows a floating label.
 */
export const highlight = async (page: Page, locator: Locator, description?: string) => {
  await locator.evaluate((el: HTMLElement, description?: string) => {
    const rect = el.getBoundingClientRect();

    // Container for highlight and text
    const container = document.createElement('div');
    container.id = 'demo-highlight-container';
    container.style.position = 'fixed';
    container.style.left = '0';
    container.style.top = '0';
    container.style.width = '100vw';
    container.style.height = '100vh';
    container.style.zIndex = '999999';
    container.style.pointerEvents = 'none';
    document.body.appendChild(container);

    // Dark overlay with a hole (using SVG mask for better effect)
    const overlay = document.createElement('div');
    overlay.style.position = 'absolute';
    overlay.style.width = '100%';
    overlay.style.height = '100%';
    overlay.style.backgroundColor = 'rgba(0, 0, 0, 0.6)';
    overlay.style.maskImage = `radial-gradient(circle at ${rect.left + rect.width / 2}px ${rect.top + rect.height / 2}px, transparent ${Math.max(rect.width, rect.height) / 1.5}px, black ${Math.max(rect.width, rect.height) / 1.5 + 40}px)`;
    overlay.style.webkitMaskImage = overlay.style.maskImage;
    container.appendChild(overlay);

    // Yellow border highlight
    const highlightElement = document.createElement('div');
    highlightElement.style.position = 'absolute';
    highlightElement.style.left = `${rect.left - 4}px`;
    highlightElement.style.top = `${rect.top - 4}px`;
    highlightElement.style.width = `${rect.width + 8}px`;
    highlightElement.style.height = `${rect.height + 8}px`;
    highlightElement.style.border = '4px solid #FACC15';
    highlightElement.style.borderRadius = '8px';
    highlightElement.style.backgroundColor = 'rgba(250, 204, 21, 0.1)';
    container.appendChild(highlightElement);

    if (description) {
      const text = document.createElement('div');
      text.innerText = description;
      text.style.position = 'absolute';
      text.style.left = '50%';
      text.style.transform = 'translateX(-50%)';
      // If the element is in the bottom half of the screen, show text at the top
      if (rect.top > window.innerHeight / 2) {
        text.style.top = `${rect.top - 80}px`;
      } else {
        text.style.top = `${rect.bottom + 40}px`;
      }
      text.style.color = 'white';
      text.style.backgroundColor = 'rgba(0, 0, 0, 0.8)';
      text.style.padding = '12px 24px';
      text.style.borderRadius = '32px';
      text.style.fontSize = '20px';
      text.style.fontWeight = 'bold';
      text.style.textAlign = 'center';
      text.style.border = '2px solid #FACC15';
      text.style.boxShadow = '0 10px 25px rgba(0,0,0,0.5)';
      text.style.maxWidth = '80%';
      container.appendChild(text);
    }
  }, description);

  // Wait a bit for the viewer to notice
  await page.waitForTimeout(1500);
};

/**
 * Multiple spotlight effect: highlights multiple elements at once using SVG masks.
 */
export const spotlightMultiple = async (page: Page, elements: { locator: Locator; description?: string }[]) => {
  const elementsData = await Promise.all(elements.map(async e => {
    const rect = await e.locator.evaluate(el => el.getBoundingClientRect());
    return { rect, description: e.description };
  }));

  await page.evaluate((data) => {
    const container = document.createElement('div');
    container.id = 'demo-highlight-container';
    container.style.position = 'fixed';
    container.style.left = '0';
    container.style.top = '0';
    container.style.width = '100vw';
    container.style.height = '100vh';
    container.style.zIndex = '999999';
    container.style.pointerEvents = 'none';
    document.body.appendChild(container);

    // Create SVG for masks
    const svgNS = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(svgNS, "svg");
    svg.setAttribute("width", "100%");
    svg.setAttribute("height", "100%");
    svg.style.position = "absolute";

    const defs = document.createElementNS(svgNS, "defs");
    const mask = document.createElementNS(svgNS, "mask");
    mask.setAttribute("id", "spotlight-mask");

    // Background of mask (white shows content, black hides)
    const maskRect = document.createElementNS(svgNS, "rect");
    maskRect.setAttribute("width", "100%");
    maskRect.setAttribute("height", "100%");
    maskRect.setAttribute("fill", "white");
    mask.appendChild(maskRect);

    data.forEach(e => {
      const rect = e.rect;
      const circle = document.createElementNS(svgNS, "circle");
      const radius = Math.max(rect.width, rect.height) / 1.5 + 20;
      circle.setAttribute("cx", (rect.left + rect.width / 2).toString());
      circle.setAttribute("cy", (rect.top + rect.height / 2).toString());
      circle.setAttribute("r", radius.toString());
      circle.setAttribute("fill", "black");
      circle.setAttribute("filter", "url(#blur)");
      mask.appendChild(circle);
    });

    const filter = document.createElementNS(svgNS, "filter");
    filter.setAttribute("id", "blur");
    const gaussian = document.createElementNS(svgNS, "feGaussianBlur");
    gaussian.setAttribute("stdDeviation", "10");
    filter.appendChild(gaussian);
    defs.appendChild(filter);

    defs.appendChild(mask);
    svg.appendChild(defs);
    container.appendChild(svg);

    // Dark overlay that uses the mask
    const overlay = document.createElement('div');
    overlay.style.position = 'absolute';
    overlay.style.width = '100%';
    overlay.style.height = '100%';
    overlay.style.backgroundColor = 'rgba(0, 0, 0, 0.6)';
    overlay.style.mask = "url(#spotlight-mask)";
    overlay.style.webkitMask = "url(#spotlight-mask)";
    container.appendChild(overlay);

    // Add yellow borders
    data.forEach(e => {
      const rect = e.rect;
      const highlightElement = document.createElement('div');
      highlightElement.style.position = 'absolute';
      highlightElement.style.left = `${rect.left - 4}px`;
      highlightElement.style.top = `${rect.top - 4}px`;
      highlightElement.style.width = `${rect.width + 8}px`;
      highlightElement.style.height = `${rect.height + 8}px`;
      highlightElement.style.border = '4px solid #FACC15';
      highlightElement.style.borderRadius = '8px';
      highlightElement.style.backgroundColor = 'rgba(250, 204, 21, 0.1)';
      container.appendChild(highlightElement);
    });
  }, elementsData);

  await page.waitForTimeout(1500);
};

/**
 * Removes all highlights from the page.
 */
export const clearHighlights = async (page: Page) => {
  await page.evaluate(() => document.getElementById('demo-highlight-container')?.remove());
};

/**
 * Clicks a button and shows a ripple effect.
 */
export const clickWithRipple = async (page: Page, locator: Locator) => {
  const box = await locator.boundingBox();
  if (!box) return;

  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  // The ripple is already handled by the initScript in the tests, 
  // but we can add manual triggers here if needed.
};

/**
 * Setup common page features like click visualization.
 */
export const setupMarketingPage = async (page: Page) => {
  await page.addInitScript(() => {
    window.addEventListener('click', (e) => {
      const circle = document.createElement('div');
      circle.style.position = 'fixed';
      circle.style.width = '40px';
      circle.style.height = '40px';
      circle.style.borderRadius = '50%';
      circle.style.backgroundColor = 'rgba(250, 204, 21, 0.4)';
      circle.style.border = '2px solid white';
      circle.style.left = `${e.clientX - 20}px`;
      circle.style.top = `${e.clientY - 20}px`;
      circle.style.pointerEvents = 'none';
      circle.style.zIndex = '999999';
      circle.style.transition = 'all 0.5s ease-out';
      document.body.appendChild(circle);
      setTimeout(() => {
        circle.style.transform = 'scale(2.5)';
        circle.style.opacity = '0';
      }, 0);
      setTimeout(() => circle.remove(), 500);
    }, true);
  });
};
