const fs = require('fs');
const path = require('path');

const pages = [
  { name: 'Home', url: 'https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sX2VjN2ZmODc4NzQ4YTQ0MjViZTkxOGExYTNhMmJiODE5EgsSBxDJmOHlnRoYAZIBJAoKcHJvamVjdF9pZBIWQhQxMjE0MjgwNzM1NTc2NjMxOTI3Nw&filename=&opi=89354086', route: '/' },
  { name: 'Shop', url: 'https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzFlM2E5YjQzZWI4YzRlNTQ5YjYxYzE5MmI1OGZmYTI2EgsSBxDJmOHlnRoYAZIBJAoKcHJvamVjdF9pZBIWQhQxMjE0MjgwNzM1NTc2NjMxOTI3Nw&filename=&opi=89354086', route: '/shop' },
  { name: 'Product', url: 'https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sX2E1OGI1NzM5ZmI0ZjQzYWY4MjAyMmVjOWNkMTBiNmMwEgsSBxDJmOHlnRoYAZIBJAoKcHJvamVjdF9pZBIWQhQxMjE0MjgwNzM1NTc2NjMxOTI3Nw&filename=&opi=89354086', route: '/product' },
  { name: 'Cart', url: 'https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sX2JhOGI1MzRiNTRjNjRhMTdhMDU0NjBjZWM0MmFjOWFiEgsSBxDJmOHlnRoYAZIBJAoKcHJvamVjdF9pZBIWQhQxMjE0MjgwNzM1NTc2NjMxOTI3Nw&filename=&opi=89354086', route: '/cart' },
  { name: 'About', url: 'https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sX2I3YTE3YTVmODc2NDRmNGRiZmUwYmNjNjY3MGMzZWJkEgsSBxDJmOHlnRoYAZIBJAoKcHJvamVjdF9pZBIWQhQxMjE0MjgwNzM1NTc2NjMxOTI3Nw&filename=&opi=89354086', route: '/about' },
  { name: 'Contact', url: 'https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzM0MzY5MzEyOTVkNDQ3MDQ4YzBlNTcxN2Y3ZTEzYzhkEgsSBxDJmOHlnRoYAZIBJAoKcHJvamVjdF9pZBIWQhQxMjE0MjgwNzM1NTc2NjMxOTI3Nw&filename=&opi=89354086', route: '/contact' }
];

async function run() {
  for (const page of pages) {
    console.log('Fetching', page.name);
    const res = await fetch(page.url);
    const html = await res.text();
    
    // extract body
    let bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
    if (!bodyMatch) {
      console.log('No body found for', page.name);
      continue;
    }
    let content = bodyMatch[1];
    
    // Convert to JSX
    content = content.replace(/class=/g, 'className=')
      .replace(/for=/g, 'htmlFor=')
      .replace(/tabindex=/g, 'tabIndex=')
      .replace(/<!--([\s\S]*?)-->/g, '{/* $1 */}')
      // self close void elements
      .replace(/<(img|input|br|hr)([^>]*[^/])>/g, '<$1$2 />')
      // fix unclosed br without space
      .replace(/<br>/g, '<br />')
      .replace(/<hr>/g, '<hr />')
      .replace(/stroke-width=/g, 'strokeWidth=')
      .replace(/stroke-opacity=/g, 'strokeOpacity=')
      // fix boolean attributes
      .replace(/disabled=""/g, 'disabled')
      .replace(/required=""/g, 'required')
      .replace(/checked=""/g, 'checked')
      .replace(/selected=""/g, '')
      .replace(/rows="(\d+)"/g, 'rows={$1}');

    // Handle the specific style="background-image: url('...');"
    content = content.replace(/style="([^"]*?)"/g, (match, styles) => {
        let reactStyles = {};
        styles.split(';').forEach(s => {
            if (!s.trim()) return;
            let [key, val] = s.split(':');
            if(key && val) {
                let camelKey = key.trim().replace(/-([a-z])/g, g => g[1].toUpperCase());
                reactStyles[camelKey] = val.trim().replace(/'/g, "\\'");
            }
        });
        let styleStr = Object.entries(reactStyles).map(([k,v]) => `${k}: '${v}'`).join(', ');
        return `style={{${styleStr}}}`;
    });

    // Replace <a href="#"> with Link
    content = content.replace(/<a([^>]*)href="#"([^>]*)>([\s\S]*?)<\/a>/g, (fullMatch, pre, post, text) => {
        let textLower = text.replace(/<[^>]*>/g, '').trim().toLowerCase();
        let target = '/';
        if (textLower.includes('shop') || textLower.includes('collection')) target = '/shop';
        if (textLower.includes('about')) target = '/about';
        if (textLower.includes('contact')) target = '/contact';
        if (textLower.includes('cart') || pre.includes('shopping_cart')) target = '/cart';
        
        // Product specific (if it's not a nav link, e.g. "Add to Cart" or image wrapper)
        if (pre.includes('group') || textLower.includes('add to cart') || textLower.includes('view all')) {
            target = '/product';
        }

        return `<Link ${pre} href="${target}" ${post}>${text}</Link>`;
    });
    
    // Replace icon buttons that act like links
    content = content.replace(/<button([^>]*)><span([^>]*)>shopping_cart<\/span><\/button>/g, '<Link href="/cart"$1><span$2>shopping_cart</span></Link>');
    content = content.replace(/<button([^>]*)><span([^>]*)>person<\/span><\/button>/g, '<Link href="/about"$1><span$2>person</span></Link>');

    // Replace product images / titles to link to product detail
    content = content.replace(/<img([^>]*)src="([^"]*)"([^>]*)>/gi, (match) => {
      // Wrap images with link if they are product looking
      return match; // To avoid breaking layout, we won't wrap images randomly, just let user click buttons.
    });

    // Make the content a single JSX fragment
    const componentStr = `"use client";
import Link from 'next/link';

export default function ${page.name}Page() {
  return (
    <>
      ${content}
    </>
  );
}
`;

    let dirPath = page.route === '/' ? 'src/app' : `src/app${page.route}`;
    fs.mkdirSync(dirPath, { recursive: true });
    fs.writeFileSync(path.join(dirPath, 'page.tsx'), componentStr);
    console.log('Wrote', page.name);
  }
}

run();
