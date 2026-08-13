class EffectRegistry {
    static registry = {};

    static register(name, effectClass) {
        this.registry[name] = effectClass;
    }

    static create(name, parameters) {
        const EffectClass = this.registry[name];
        if (EffectClass) {
            return new EffectClass(parameters);
        }
        console.warn(`[EffectRegistry] Unknown effect: ${name}`);
        return null;
    }

    static getRegisteredEffects() {
        return Object.keys(this.registry);
    }
}
