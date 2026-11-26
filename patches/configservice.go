package main

import (
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"go.yaml.in/yaml/v3"
)

type ConfigService struct{}

type Account struct {
	Name           string    `json:"name" koanf:"name"`
	Cookies        string    `json:"cookies" koanf:"cookies"`
	Proxy          string    `json:"proxy" koanf:"proxy"`
	TokenSK        string    `json:"tokenSk" koanf:"-"`
	Login          string    `json:"login" koanf:"-"`
	CoinBalance    string    `json:"coinBalance" koanf:"-"`
	RewardsJson    string    `json:"rewardsJson" koanf:"-"`
	LastAuth       time.Time `json:"-" koanf:"-"`
	SignInInfoJson string    `json:"signInInfoJson" koanf:"-"`
	AppVersion     string    `json:"-" koanf:"-"`
	FrontGlue      string    `json:"-" koanf:"-"`
	Language       string    `json:"-" koanf:"-"`
}

type GlobalSettings struct {
	Accounts []Account `json:"accounts" koanf:"accounts"`
}

type diskAccount struct {
	Name    string `yaml:"name"`
	Cookies string `yaml:"cookies"`
	Proxy   string `yaml:"proxy"`
}
type diskConfig struct {
	Accounts []diskAccount `yaml:"accounts"`
}

var configMu sync.Mutex

func configPath() (string, error) {
	exe, err := os.Executable()
	if err != nil {
		return "", errors.New("cannot locate application directory")
	}
	return filepath.Join(filepath.Dir(exe), "config.dpapi"), nil
}

func readConfig(path string) (GlobalSettings, error) {
	out := GlobalSettings{Accounts: []Account{}}
	cipher, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return out, nil
	}
	if err != nil {
		return out, errors.New("cannot read encrypted configuration")
	}
	plain, err := unprotectConfig(cipher)
	if err != nil {
		return out, errors.New("cannot decrypt configuration (use the original Windows account)")
	}
	defer clear(plain)
	var data diskConfig
	if err := yaml.Unmarshal(plain, &data); err != nil {
		return out, errors.New("invalid configuration format")
	}
	for _, a := range data.Accounts {
		raw, err := base64.StdEncoding.DecodeString(a.Cookies)
		if err != nil || len(raw) == 0 {
			clear(raw)
			return GlobalSettings{}, errors.New("invalid saved account cookies")
		}
		clear(raw)
		out.Accounts = append(out.Accounts, Account{Name: a.Name, Cookies: a.Cookies, Proxy: a.Proxy})
	}
	return out, nil
}

func writeConfig(path string, cfg GlobalSettings) error {
	data := diskConfig{Accounts: make([]diskAccount, 0, len(cfg.Accounts))}
	for _, a := range cfg.Accounts {
		data.Accounts = append(data.Accounts, diskAccount{a.Name, a.Cookies, a.Proxy})
	}
	plain, err := yaml.Marshal(data)
	if err != nil {
		return errors.New("cannot serialize configuration")
	}
	defer clear(plain)
	cipher, err := protectConfig(plain)
	if err != nil {
		return errors.New("cannot encrypt configuration")
	}
	f, err := os.CreateTemp(filepath.Dir(path), ".config-*.tmp")
	if err != nil {
		return errors.New("cannot create configuration temporary file")
	}
	defer os.Remove(f.Name())
	if _, err = f.Write(cipher); err != nil {
		f.Close()
		return errors.New("cannot write configuration")
	}
	if err = f.Sync(); err != nil {
		f.Close()
		return errors.New("cannot sync configuration")
	}
	if err = f.Close(); err != nil {
		return errors.New("cannot close configuration")
	}
	if err = os.Rename(f.Name(), path); err != nil {
		return errors.New("cannot replace configuration")
	}
	return nil
}

func (g *ConfigService) GetConfig(_ struct{}) (GlobalSettings, error) {
	configMu.Lock()
	defer configMu.Unlock()
	path, err := configPath()
	if err != nil {
		return GlobalSettings{}, err
	}
	return readConfig(path)
}

func mutateConfig(change func(*GlobalSettings) error) error {
	configMu.Lock()
	defer configMu.Unlock()
	path, err := configPath()
	if err != nil {
		return err
	}
	cfg, err := readConfig(path)
	if err != nil {
		return err
	}
	if err = change(&cfg); err != nil {
		return err
	}
	return writeConfig(path, cfg)
}

func encodeAccount(account Account) (Account, error) {
	if account.Cookies == "" {
		return Account{}, errors.New("cookies are required")
	}
	return Account{Name: account.Name, Cookies: base64.StdEncoding.EncodeToString([]byte(account.Cookies)), Proxy: account.Proxy}, nil
}

func (g *ConfigService) AddAccountToConfig(account Account) error {
	a, err := encodeAccount(account)
	if err != nil {
		return err
	}
	return mutateConfig(func(cfg *GlobalSettings) error {
		for _, existing := range cfg.Accounts {
			if existing.Cookies == a.Cookies {
				return errors.New("account already exists")
			}
		}
		cfg.Accounts = append(cfg.Accounts, a)
		return nil
	})
}

func (g *ConfigService) RemoveAccountFromConfig(target Account) error {
	return mutateConfig(func(cfg *GlobalSettings) error {
		for i, a := range cfg.Accounts {
			if a.Cookies == target.Cookies {
				cfg.Accounts = append(cfg.Accounts[:i], cfg.Accounts[i+1:]...)
				return nil
			}
		}
		return fmt.Errorf("account not found")
	})
}

func (g *ConfigService) UpdateAccountInConfig(old Account, updated Account) error {
	a, err := encodeAccount(updated)
	if err != nil {
		return err
	}
	return mutateConfig(func(cfg *GlobalSettings) error {
		idx := -1
		for i, existing := range cfg.Accounts {
			if existing.Cookies == old.Cookies {
				idx = i
			} else if existing.Cookies == a.Cookies {
				return errors.New("account already exists")
			}
		}
		if idx == -1 {
			return errors.New("account not found")
		}
		cfg.Accounts[idx] = a
		return nil
	})
}
