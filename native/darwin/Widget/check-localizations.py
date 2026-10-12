"""Nine-language widget copy contract, independent of Vue locales."""
import pathlib
import re
import subprocess

root = pathlib.Path(__file__).parent / 'Resources'
keys = {'timeline', 'description', 'empty', 'sync', 'updated'}
languages = {'zh-CN', 'zh-Hant', 'en', 'ja', 'ko', 'de', 'fr', 'es', 'pt-BR'}
assert {p.stem for p in root.glob('*.lproj')} == languages
english = None
translations = {}
for language in languages:
    path = root / (language + '.lproj') / 'Localizable.strings'
    subprocess.run(['plutil', '-lint', str(path)], check=True, capture_output=True)
    pairs = re.findall(r'^"([^"]+)" = "([^"]+)";$', path.read_text(), re.M)
    assert len(pairs) == len(keys), language
    copy = dict(pairs)
    assert set(copy) == keys and all(copy.values()), language
    translations[language] = copy
english = translations['en']
for language, copy in translations.items():
    if language != 'en':
        assert all(value != english[key] for key, value in copy.items()), language
print('widget: nine-language keys, nonempty translations and plist syntax passed')
