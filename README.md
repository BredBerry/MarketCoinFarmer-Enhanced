<div align="center">

# Market Coin Farmer Enhanced

**Yandex Market Rewards & Coins · Windows Desktop Application**

**Монеты, ежедневные награды и колесо призов Яндекс Маркета**

![Release](https://img.shields.io/github/v/release/BredBerry/MarketCoinFarmer-Enhanced?label=release&color=2563eb&style=flat-square)
![Windows](https://img.shields.io/badge/Windows-10%20%2F%2011%20x64-0078d4?style=flat-square)
![Go](https://img.shields.io/badge/Go-00ADD8?style=flat-square&logo=go&logoColor=white)
![Vue](https://img.shields.io/badge/Vue-35495e?style=flat-square&logo=vuedotjs&logoColor=4FC08D)
![Wails](https://img.shields.io/badge/Wails-v3-dc2626?style=flat-square)
![DPAPI](https://img.shields.io/badge/Storage-Windows%20DPAPI-0e7490?style=flat-square)
![Downloads](https://img.shields.io/github/downloads/BredBerry/MarketCoinFarmer-Enhanced/total?style=flat-square&color=2563eb)
![Stars](https://img.shields.io/github/stars/BredBerry/MarketCoinFarmer-Enhanced?style=flat-square)

[![Download for Windows](https://img.shields.io/badge/DOWNLOAD%20FOR%20WINDOWS-EXE%20x64-2563eb?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases/latest/download/market-coin-farmer.exe)

[Latest release / Последний релиз](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases/latest) · [Changelog](CHANGELOG.md) · [Security](SECURITY.md)

[🇬🇧 English](#english) &nbsp; | &nbsp; [🇷🇺 Русский](#русский)

</div>

---

## English

### About

**Market Coin Farmer Enhanced** is an unofficial Windows desktop modification of [xob0t/market-coin-farmer](https://github.com/xob0t/market-coin-farmer) for managing Yandex Market coins and daily rewards. It brings together account management, reward information and prize-wheel functionality, with compatibility fixes for the Market API, improved local credential storage and a Windows build toolkit.

| Feature | Enhanced V3 |
| :--- | :--- |
| **Market compatibility** | Handles the observed `mf-promoloyalty.` version format |
| **Account management** | Multiple accounts, optional per-account proxy and duplicate-cookie checks |
| **Rewards & coins** | View balances, daily rewards and prize-wheel features |
| **Encrypted storage** | Windows DPAPI (CurrentUser) for saved cookies and proxy settings |
| **Privacy improvements** | Direct account-object logging removed; browser cookie domain filtering |
| **Interface** | Improved notification contrast and masked proxy details |
| **Build toolkit** | Pinned upstream revision, npm audit gates and regression tests |

### Download & quick start

| Download | Description |
| :--- | :--- |
| [**market-coin-farmer.exe**](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases/latest/download/market-coin-farmer.exe) | Ready-to-run Windows x64 application |
| [**V3 Builder ZIP**](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases/download/v1.3.0-enhanced.3/Market_Coin_Farmer_Improved_Builder_v3.zip) | Build scripts, patches and regression tests |

1. Download the EXE and place it in a dedicated writable folder.
2. Run it as a regular Windows user, without administrator privileges.
3. Add an account and choose browser sign-in. Authenticate with your own Yandex account.
4. Check the displayed coin balance and available rewards.

**Requirements:** Windows 10/11 x64, [Microsoft Edge WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/) and Edge or Chrome for browser sign-in. Git, Go, Node.js, Wails and Task are **not required** to run the ready-made EXE.

### Release integrity & security

The [v1.3.0-enhanced.3 release](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases/tag/v1.3.0-enhanced.3) was built on 27 November 2026 (local time).

| Check | Recorded release result |
| :--- | :--- |
| Windows x64 build | Passed |
| TestMCF regression tests | Passed |
| Go module integrity | Passed |
| [Full npm audit](recovery/npm-audit-all.json) | 0 findings |
| [Production npm audit](recovery/npm-audit-production.json) | 0 findings |

Verify the V3 EXE in PowerShell from its folder:

```powershell
Get-FileHash .\market-coin-farmer.exe -Algorithm SHA256
```

Expected SHA-256 for **v1.3.0-enhanced.3**:

```text
2d58e85a3c5b9c3ada3f7973e16b438ce2239ed32f0c84ce96b46239d5693b04
```

> These are recorded build results, not an independent malware assessment. The EXE has not been independently audited. A zero-finding npm audit does not rule out vulnerabilities in Go, WebView2 or the application itself. DPAPI protects data at rest, not against all processes running as the same Windows user.

### Build from source

**Build requirements:** Git, Go 1.26+, Node.js with npm, Wails v3.0.0-beta.5, Task v3 and WebView2. The recorded build used Go 1.27.4, Node.js 26.13.1, npm 11.20.0 and Task 3.54.0.

Clone the repository or extract the builder ZIP, then open Command Prompt in the folder containing `BUILD.bat`:

```cmd
git clone https://github.com/BredBerry/MarketCoinFarmer-Enhanced.git
cd MarketCoinFarmer-Enhanced
BUILD.bat -NoImport
```

To import an existing encrypted configuration, close all application windows and specify the actual installation folder:

```cmd
BUILD.bat -LegacyFolder "C:\Path\To\Market Coin Farmer"
```

Use one of these explicit options: the original V3 builder has a historical default path that is not portable. It clones upstream commit [27b6c1a0](https://github.com/xob0t/market-coin-farmer/commit/27b6c1a0750c4bd595b565a3c14c5000455f3314), applies patches, updates npm dependencies within allowed ranges, runs audits and tests, and creates a separate installation on the desktop. Existing installations are not overwritten. Build reports and source are kept in `%LOCALAPPDATA%\MCFBuilder\<id>`.

The [archived lockfile](recovery/package-lock.json) documents the release dependencies. The builder recalculates dependencies on future builds, so byte-for-byte reproducibility is not guaranteed.

### Configuration & troubleshooting

- **Configuration:** `config.dpapi` is saved beside the EXE. Back it up offline; keep it with the EXE when moving folders under the same Windows user. After a Windows reinstall or user change, sign-in may be required again.
- **Browser sign-in fails:** close existing browser processes after saving your work, check Edge/Chrome availability and try again.
- **Market request context is missing:** check that you are using the latest release. Market-side changes may require a future compatibility update.
- **Build fails:** check tool versions, network connectivity and the builder's error output. Do not force dependency upgrades to bypass its security gates.

Never publish cookies, proxy passwords, tokens, `config.dpapi` or `config.yaml`. See [security guidance](SECURITY.md).

---

## Русский

### О проекте

**Market Coin Farmer Enhanced** — неофициальная модификация программы [Market Coin Farmer](https://github.com/xob0t/market-coin-farmer) для работы с монетами и ежедневными наградами Яндекс Маркета на Windows. Приложение объединяет управление аккаунтами, просмотр баланса монет и наград, а также функции колеса призов. Enhanced V3 добавляет исправления совместимости с API Маркета, шифрование настроек и автоматизированную сборку.

### Возможности Enhanced V3

| Возможность | Описание |
| :--- | :--- |
| **Монеты Яндекс Маркета** | Просмотр баланса и работа с доступными наградами |
| **Ежедневные награды и колесо призов** | Функции оригинального приложения в одном интерфейсе |
| **Мультиаккаунт** | Управление несколькими собственными аккаунтами и необязательными прокси |
| **Совместимость** | Поддержка формата версии Маркета с префиксом `mf-promoloyalty.` |
| **Шифрование cookies** | Windows DPAPI (CurrentUser) защищает сохранённые cookies и параметры прокси |
| **Конфиденциальность** | Удалён прямой вывод объектов аккаунтов в логи; ограничен импорт браузерных cookies по доменам |
| **Интерфейс** | Улучшена читаемость уведомлений, скрыты данные прокси на карточке |
| **Сборка** | Автоматизированная сборка Windows x64 с npm audit и регрессионными тестами |

### Скачать Market Coin Farmer для Windows

[![Скачать EXE](https://img.shields.io/badge/СКАЧАТЬ%20EXE-WINDOWS%20x64-2563eb?style=for-the-badge)](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases/latest/download/market-coin-farmer.exe)

| Файл | Назначение |
| :--- | :--- |
| [**market-coin-farmer.exe**](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases/latest/download/market-coin-farmer.exe) | Готовая программа, не требует сборки |
| [**Сборщик Enhanced V3 (ZIP)**](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases/download/v1.3.0-enhanced.3/Market_Coin_Farmer_Improved_Builder_v3.zip) | Скрипты сборки, патчи и тесты |

Скачивание доступно без авторизации в GitHub.

### Установка и запуск

1. Скачайте EXE и поместите его в отдельную папку с доступом на запись.
2. Запустите программу без прав администратора.
3. Добавьте аккаунт, выберите вход через браузер и авторизуйтесь в своём аккаунте Яндекса.
4. Проверьте баланс монет и доступные награды.

**Системные требования:** Windows 10/11 x64, [Microsoft Edge WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/) и браузер Edge или Chrome для авторизации. Прокси необязателен.

Для готового EXE устанавливать Git, Go, Node.js, Wails и Task **не нужно**.

### Безопасность и проверка файла

В релизе V3 сохранённые данные аккаунтов шифруются системным механизмом Windows DPAPI. На дату сборки полный и production npm audit показали **0 известных уязвимостей**; сборщик также выполнил `go mod verify` и тесты TestMCF.

Результаты: [полный аудит](recovery/npm-audit-all.json) · [production-аудит](recovery/npm-audit-production.json).

Проверьте скачанный EXE в PowerShell:

```powershell
Get-FileHash .\market-coin-farmer.exe -Algorithm SHA256
```

Контрольная сумма V3 приведена в [разделе Release integrity & security](#release-integrity--security). Совпадение хеша подтверждает целостность файла, но не отсутствие вредоносного кода.

> Независимый аудит готового EXE не проведён. Нулевой результат npm audit не гарантирует полной безопасности. DPAPI не защищает от всех процессов, запущенных с правами текущего пользователя.

### Самостоятельная сборка

Установите Git, Go 1.26+, Node.js с npm, Wails v3.0.0-beta.5, Task v3 и WebView2. Распакуйте сборщик либо клонируйте репозиторий. Откройте CMD в папке с `BUILD.bat`.

Чистая сборка без переноса аккаунтов:

```cmd
BUILD.bat -NoImport
```

Перенос существующей зашифрованной конфигурации (укажите свою папку):

```cmd
BUILD.bat -LegacyFolder "C:\Path\To\Market Coin Farmer"
```

Перед переносом закройте все окна программы. Не запускайте исходный сборщик V3 без параметров: в нём сохранён исторический путь к старой V2.

Сборщик получает фиксированный коммит оригинального проекта, применяет исправления, обновляет npm-зависимости без `--force`, выполняет проверки и создаёт новую папку на рабочем столе. Старая установка не перезаписывается. При ошибке сборка останавливается.

Отчёты и исходники: `%LOCALAPPDATA%\MCFBuilder\<id>`. [Lock-файл релиза](recovery/package-lock.json) сохранён отдельно; при повторной сборке версии зависимостей могут измениться.

### Частые вопросы

**Где хранятся аккаунты?**  
В файле `config.dpapi` рядом с EXE. Храните резервную копию локально. После переустановки Windows или смены пользователя может потребоваться повторный вход.

**Почему не открывается браузер авторизации?**  
Сохраните работу, закройте запущенные окна браузера, проверьте наличие Chrome или Edge и повторите вход.

**Что делать при ошибке Market request context is missing?**  
Проверьте версию программы. При изменениях API Маркета могут понадобиться новые исправления.

**Можно ли использовать без установки среды разработки?**  
Да. Для запуска готового EXE нужен WebView2, но не инструменты сборки.

Никогда не публикуйте `config.dpapi`, `config.yaml`, cookies, токены и пароли.

---

## Repository structure / Структура проекта

```text
MarketCoinFarmer-Enhanced/
├── BUILD.bat
├── build.ps1
├── patches/
│   ├── configservice.go
│   ├── dpapi_windows.go
│   └── mcf_hardening_test.go
├── recovery/
│   ├── package-lock.json
│   ├── npm-audit-all.json
│   └── npm-audit-production.json
├── README_RU.txt
├── CHANGELOG.md
└── SECURITY.md
```

## Credits, rights & limitations / Авторство и ограничения

Original project / Оригинальный проект: **[xob0t/market-coin-farmer](https://github.com/xob0t/market-coin-farmer)**. Enhanced maintenance / Доработка: **[BredBerry](https://github.com/BredBerry)**.

This is an unofficial modification, not affiliated with Yandex. No upstream license was identified; permission to publicly redistribute modified code or binaries has not been confirmed. Public availability does not grant redistribution rights. Use only accounts you are authorized to access and comply with the service's terms. Market API changes can break functionality; rewards, uninterrupted operation and freedom from account restrictions are not guaranteed.

Это неофициальная модификация, не связанная с Яндексом. Лицензия оригинального проекта не обнаружена; разрешение правообладателя на публичное распространение не подтверждено. Публичный доступ сам по себе не предоставляет прав на распространение. Используйте только аккаунты, к которым имеете законный доступ, и соблюдайте правила сервиса. Начисление наград, бесперебойная работа и отсутствие ограничений аккаунтов не гарантируются.

<div align="center">

[Releases / Релизы](https://github.com/BredBerry/MarketCoinFarmer-Enhanced/releases) · [Changelog / Изменения](CHANGELOG.md) · [Security / Безопасность](SECURITY.md)

</div>
