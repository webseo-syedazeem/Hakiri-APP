import re
import urllib.request
import os

with open('doc_content.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Remove style tags and find text structure
# Print text paragraphs
from html.parser import HTMLParser

class DocParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text = []
        self.images = []

    def handle_starttag(self, tag, attrs):
        if tag == 'img':
            attrs_dict = dict(attrs)
            if 'src' in attrs_dict:
                self.images.append(attrs_dict['src'])
                self.text.append(f"\n[IMAGE_{len(self.images)-1}]\n")

    def handle_data(self, data):
        cleaned = data.strip()
        if cleaned:
            self.text.append(cleaned)

parser = DocParser()
parser.feed(html)

print("=== DOCUMENT TEXT ===")
print(" ".join(parser.text[:100]))
print(f"Total images: {len(parser.images)}")

os.makedirs('doc_images', exist_ok=True)
for i, url in enumerate(parser.images):
    fn = f'doc_images/img_{i}.png'
    try:
        urllib.request.urlretrieve(url, fn)
        print(f"Saved {fn} from {url[:60]}")
    except Exception as e:
        print(f"Error saving image {i}: {e}")
