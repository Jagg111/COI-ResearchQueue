using Mafi;
using Mafi.Collections;
using Mafi.Core;
using Mafi.Core.Game;
using Mafi.Core.Mods;
using Mafi.Core.Prototypes;

namespace ResearchQueue;

/// <summary>
/// Main mod entry point. The queue panel (embedded in the research tree)
/// is handled by ResearchQueueWindowController, auto-registered via
/// [GlobalDependency].
/// </summary>
public sealed class ResearchQueueMod : IMod {

	public string Name => "ResearchQueue";
	public int Version => 1;
	public bool IsUiOnly => false;

	public ModManifest Manifest { get; }
	public Option<IConfig> ModConfig => Option<IConfig>.None;
	public ModJsonConfig JsonConfig { get; }

	public ResearchQueueMod(ModManifest manifest) {
		Manifest = manifest;
		JsonConfig = new ModJsonConfig(this);
		Log.Info("ResearchQueue: constructed");
	}

	public void Initialize(DependencyResolver resolver, bool gameWasLoaded) {
		Log.Info("ResearchQueue: Initialize called, gameWasLoaded=" + gameWasLoaded);
	}

	public void ChangeConfigs(Lyst<IConfig> configs) { }

	public void RegisterPrototypes(ProtoRegistrator registrator) {
		Log.Info("ResearchQueue: RegisterPrototypes called");
	}

	public void RegisterDependencies(
		DependencyResolverBuilder depBuilder, ProtosDb protosDb, bool wasLoaded) {
	}

	public void EarlyInit(DependencyResolver resolver) { }

	public void MigrateJsonConfig(VersionSlim savedVersion, Dict<string, object> savedValues) { }

	public void Dispose() { }
}
