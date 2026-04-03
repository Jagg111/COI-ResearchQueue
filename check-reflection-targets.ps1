# check-reflection-targets.ps1
# Verifies that all reflection targets used by the ResearchQueue mod still exist
# in the game DLLs. Run after a game update to quickly identify what broke.
#
# Usage: powershell -ExecutionPolicy Bypass -File check-reflection-targets.ps1
#
# This script parses ResearchQueueWindowController.cs to find all ReflectionProbe
# calls, then checks each target against the actual game DLLs. The C# source is
# the single source of truth -- no separate list to maintain.

$basePath = "$env:COI_ROOT\Captain of Industry_Data\Managed"
$sourceFile = Join-Path $PSScriptRoot "ResearchQueueWindowController.cs"

if (-not (Test-Path $basePath)) {
    Write-Host "ERROR: Game DLL path not found: $basePath" -ForegroundColor Red
    Write-Host "Make sure COI_ROOT environment variable is set." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $sourceFile)) {
    Write-Host "ERROR: Source file not found: $sourceFile" -ForegroundColor Red
    exit 1
}

# Load game DLLs
$dllNames = @("Mafi.dll", "Mafi.Core.dll", "Mafi.Base.dll", "Mafi.Unity.dll")
$loadedAssemblies = @{}

foreach ($dll in $dllNames) {
    $dllPath = Join-Path $basePath $dll
    if (Test-Path $dllPath) {
        try {
            $asm = [System.Reflection.Assembly]::LoadFrom($dllPath)
            $loadedAssemblies[$dll] = $asm
        } catch {
            Write-Host "WARNING: Could not load $dll" -ForegroundColor Yellow
        }
    }
}

# Parse source file for ReflectionProbe calls
# Patterns:
#   ReflectionProbe.Field(typeof(TypeName), "memberName", BindingFlags..., "feature")
#   ReflectionProbe.Field(\n  someExpr.GetType(), "memberName", ...  -- dynamic type, skip
#   ReflectionProbe.Property(typeof(TypeName), "memberName", "feature")
#   ReflectionProbe.Method(typeof(TypeName), "memberName", BindingFlags..., "feature")
#   ReflectionProbe.RecordTypeProbe("full.type.name", ..., "feature")

$source = Get-Content $sourceFile -Raw

$results = @()

# Match Field/Method calls with typeof(...)
$fieldMethodPattern = 'ReflectionProbe\.(Field|Method)\(\s*typeof\((\w+)\)\s*,\s*"([^"]+)"\s*,\s*(BindingFlags\.[^,]+(?:\s*\|\s*BindingFlags\.\w+)*)\s*,\s*"([^"]+)"'
$matches = [regex]::Matches($source, $fieldMethodPattern)
foreach ($m in $matches) {
    $results += @{
        Kind = $m.Groups[1].Value.ToLower()
        TypeName = $m.Groups[2].Value
        MemberName = $m.Groups[3].Value
        Flags = $m.Groups[4].Value
        Feature = $m.Groups[5].Value
    }
}

# Match Field/Property calls with expression.GetType() or .FieldType -- these use dynamic types
# We note them but can't check them without running the game
$dynamicFieldPattern = 'ReflectionProbe\.Field\(\s*(?:_\w+\.(?:GetType\(\)|FieldType)|_\w+\.GetType\(\)\.BaseType)\s*,\s*"([^"]+)"\s*,\s*(BindingFlags\.[^,]+(?:\s*\|\s*BindingFlags\.\w+)*)\s*,\s*"([^"]+)"'
$dynamicMatches = [regex]::Matches($source, $dynamicFieldPattern)

$dynamicPropPattern = 'ReflectionProbe\.Property\(\s*(?:\w+\.GetType\(\))\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"'
$dynamicPropMatches = [regex]::Matches($source, $dynamicPropPattern)

# Match Property calls with typeof(...)
$propertyPattern = 'ReflectionProbe\.Property\(\s*typeof\((\w+)\)\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"'
$propMatches = [regex]::Matches($source, $propertyPattern)
foreach ($m in $propMatches) {
    $results += @{
        Kind = "property"
        TypeName = $m.Groups[1].Value
        MemberName = $m.Groups[2].Value
        Flags = "Public,Instance"
        Feature = $m.Groups[3].Value
    }
}

# Match RecordTypeProbe calls
$typeProbePattern = 'ReflectionProbe\.RecordTypeProbe\(\s*"([^"]+)"'
$typeMatches = [regex]::Matches($source, $typeProbePattern)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ResearchQueue Reflection Target Check" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0
$skipped = 0

# Check statically-typed targets
foreach ($target in $results) {
    $typeName = $target.TypeName
    $memberName = $target.MemberName
    $kind = $target.Kind
    $feature = $target.Feature

    # Find the type across all loaded assemblies
    $foundType = $null
    foreach ($asm in $loadedAssemblies.Values) {
        $types = @()
        try { $types = $asm.GetTypes() } catch [System.Reflection.ReflectionTypeLoadException] {
            $types = $_.Exception.Types | Where-Object { $_ -ne $null }
        }
        $match = $types | Where-Object { $_.Name -eq $typeName } | Select-Object -First 1
        if ($match) { $foundType = $match; break }
    }

    if (-not $foundType) {
        Write-Host "  FAIL  " -NoNewline -ForegroundColor Red
        Write-Host "$kind '$memberName' -- type '$typeName' not found -- $feature"
        $failed++
        continue
    }

    # Parse binding flags
    $bindingFlags = [System.Reflection.BindingFlags]::Default
    if ($target.Flags -match "NonPublic") { $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic }
    if ($target.Flags -match "Public") { $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::Public }
    if ($target.Flags -match "Instance") { $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::Instance }
    if ($target.Flags -match "Static") { $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::Static }

    $found = $false
    switch ($kind) {
        "field" { $found = $null -ne $foundType.GetField($memberName, $bindingFlags) }
        "property" { $found = $null -ne $foundType.GetProperty($memberName) }
        "method" { $found = $null -ne $foundType.GetMethod($memberName, $bindingFlags) }
    }

    if ($found) {
        Write-Host "  PASS  " -NoNewline -ForegroundColor Green
        Write-Host "$kind '$memberName' on $($foundType.FullName) -- $feature"
        $passed++
    } else {
        Write-Host "  FAIL  " -NoNewline -ForegroundColor Red
        Write-Host "$kind '$memberName' on $($foundType.FullName) -- $feature"
        $failed++
    }
}

# Check type probes (handles nested types like Outer+Inner)
foreach ($m in $typeMatches) {
    $fullName = $m.Groups[1].Value
    $foundType = $null
    foreach ($asm in $loadedAssemblies.Values) {
        # Try direct lookup first (handles nested types with + separator)
        try { $foundType = $asm.GetType($fullName) } catch {}
        if ($foundType) { break }

        # Fallback: scan all types
        $types = @()
        try { $types = $asm.GetTypes() } catch [System.Reflection.ReflectionTypeLoadException] {
            $types = $_.Exception.Types | Where-Object { $_ -ne $null }
        }
        $match = $types | Where-Object { $_.FullName -eq $fullName } | Select-Object -First 1
        if ($match) { $foundType = $match; break }
    }

    if ($foundType) {
        Write-Host "  PASS  " -NoNewline -ForegroundColor Green
        Write-Host "type '$fullName'"
        $passed++
    } else {
        # Some types (especially nested types with Unity dependencies) can't be loaded
        # outside the game runtime. Check if subtypes exist as evidence the type is present.
        $hasSubtypes = $false
        foreach ($asm in $loadedAssemblies.Values) {
            $types = @()
            try { $types = $asm.GetTypes() } catch [System.Reflection.ReflectionTypeLoadException] {
                $types = $_.Exception.Types | Where-Object { $_ -ne $null }
            }
            $sub = $types | Where-Object { $_.FullName -like "$fullName+*" } | Select-Object -First 1
            if ($sub) { $hasSubtypes = $true; break }
        }

        if ($hasSubtypes) {
            Write-Host "  PASS* " -NoNewline -ForegroundColor Green
            Write-Host "type '$fullName' (subtypes found; parent type unloadable outside game runtime)"
            $passed++
        } else {
            Write-Host "  FAIL  " -NoNewline -ForegroundColor Red
            Write-Host "type '$fullName'"
            $failed++
        }
    }
}

# Report dynamic-type probes that can't be checked offline
$dynamicTotal = $dynamicMatches.Count + $dynamicPropMatches.Count
if ($dynamicTotal -gt 0) {
    Write-Host ""
    Write-Host "  Dynamic-type probes (require game runtime to verify):" -ForegroundColor Yellow
    foreach ($m in $dynamicMatches) {
        Write-Host "  SKIP  " -NoNewline -ForegroundColor Yellow
        Write-Host "field '$($m.Groups[1].Value)' -- $($m.Groups[3].Value)"
        $skipped++
    }
    foreach ($m in $dynamicPropMatches) {
        Write-Host "  SKIP  " -NoNewline -ForegroundColor Yellow
        Write-Host "property '$($m.Groups[1].Value)' -- $($m.Groups[2].Value)"
        $skipped++
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Results: $passed PASS, $failed FAIL, $skipped SKIP" -ForegroundColor Cyan
if ($failed -gt 0) {
    Write-Host "  Action: Run inspect_dll.ps1 on failed types to see what changed" -ForegroundColor Yellow
}
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
