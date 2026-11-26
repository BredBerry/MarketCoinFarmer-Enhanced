package main

import (
	"bytes"
	"encoding/base64"
	"os"
	"path/filepath"
	"testing"
)

func TestMCFVersionFormats(t *testing.T) {
	for _, tc := range []struct{ input, want string }{
		{`"-version":"2026.08.09-desktop.123"`, "2026.08.09-desktop.123"},
		{`"-version":"2026.10.17.0.t4814424588"`, "2026.10.17.0.t4814424588"},
		{`"-version" : "mf-promoloyalty.2026.11.21.0.t4888501980"`, "mf-promoloyalty.2026.11.21.0.t4888501980"},
		{`"-version":o.version`, ""},
		{`"-version":"nonsense"`, ""},
	} {
		if got := extractStringValue([]byte(tc.input), appVersionRegex); got != tc.want {
			t.Errorf("version extraction: got %q want %q", got, tc.want)
		}
	}
}

func TestMCFConfigDPAPI(t *testing.T) {
	path := filepath.Join(t.TempDir(), "config.dpapi")
	token := base64.StdEncoding.EncodeToString([]byte("dummy-test-cookie"))
	cfg := GlobalSettings{Accounts: []Account{{Name: "test", Cookies: token, Proxy: "http://test:dummy-secret@localhost:8000"}}}
	if err := writeConfig(path, cfg); err != nil {
		t.Fatal(err)
	}
	blob, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(blob, []byte(token)) || bytes.Contains(blob, []byte("dummy-secret")) {
		t.Fatal("plaintext in encrypted file")
	}
	got, err := readConfig(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(got.Accounts) != 1 || got.Accounts[0].Cookies != token || got.Accounts[0].Proxy != cfg.Accounts[0].Proxy {
		t.Fatal("config round trip failed")
	}
	cfg.Accounts[0].Name = "updated"
	if err := writeConfig(path, cfg); err != nil {
		t.Fatal(err)
	}
	got, err = readConfig(path)
	if err != nil || len(got.Accounts) != 1 || got.Accounts[0].Name != "updated" {
		t.Fatal("config replacement failed")
	}
	if err := os.WriteFile(path, []byte("invalid"), 0600); err != nil {
		t.Fatal(err)
	}
	if _, err := readConfig(path); err == nil {
		t.Fatal("corrupt config was accepted")
	}
}

func TestMCFCookieDomains(t *testing.T) {
	for _, d := range []string{".yandex.ru", "market.yandex.ru", "passport.yandex.com", "ya.ru"} {
		if !isMCFYandexDomain(d) {
			t.Errorf("expected allowed domain: %s", d)
		}
	}
	for _, d := range []string{"evil-yandex.ru", "yandex.ru.example.org", "microsoft.com", ""} {
		if isMCFYandexDomain(d) {
			t.Errorf("unexpected allowed domain: %s", d)
		}
	}
}

func TestMCFLegacyYAML(t *testing.T) {
	path := filepath.Join(t.TempDir(), "config.dpapi")
	legacy := []byte("accounts:\n  - name: legacy\n    cookies: ZHVtbXk=\n    proxy: \"\"\n")
	encrypted, err := protectConfig(legacy)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, encrypted, 0600); err != nil {
		t.Fatal(err)
	}
	cfg, err := readConfig(path)
	if err != nil || len(cfg.Accounts) != 1 || cfg.Accounts[0].Name != "legacy" || cfg.Accounts[0].Cookies != "ZHVtbXk=" {
		t.Fatal("legacy YAML migration failed")
	}
}
