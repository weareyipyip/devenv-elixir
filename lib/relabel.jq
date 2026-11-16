# syft labels every OTP application pkg:otp; Hex dependencies from mix.lock become pkg:hex to match advisories
[$lock | scan("\"([a-z0-9_]+)\": \\{:hex")[0]] as $hex
# syft guesses name:name as CPE vendor and product for Nix packages, which does not match NVD
| {
    glibc: "gnu:glibc",
    gcc: "gnu:gcc",
    coreutils: "gnu:coreutils",
    ncurses: "gnu:ncurses",
    readline: "gnu:readline",
    gawk: "gnu:gawk",
    gnugrep: "gnu:grep",
    gnused: "gnu:sed",
    libidn2: "gnu:libidn2",
    libunistring: "gnu:libunistring",
    "gmp-with-cxx": "gmplib:gmp",
    pcre2: "pcre:pcre2",
    openssl: "openssl:openssl",
    zlib: "zlib:zlib"
  } as $nixCpe
| .components |= map(
    # Hex packages match on purl and bundled OTP applications on Erlang's CPE, so the guessed CPE goes
    if (.purl // "" | startswith("pkg:otp/")) then
        del(.cpe)
        | if (.name | IN($hex[])) then .purl |= sub("^pkg:otp/"; "pkg:hex/") else . end
      else . end
    | if .purl then .purl |= (
        sub("^pkg:generic/erlang@"; "pkg:github/erlang/otp@OTP-")
        | sub("^pkg:generic/elixir@"; "pkg:github/elixir-lang/elixir@v")
      ) else . end
    | if (.purl // "" | startswith("pkg:nix/")) then
        $nixCpe[.name] as $product
        | if $product
          then .cpe = "cpe:2.3:a:\($product):\(.version | sub("(-|p)[0-9]+$"; "")):*:*:*:*:*:*:*"
          else del(.cpe) end
      else . end
  )
