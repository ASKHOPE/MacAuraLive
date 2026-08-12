class MacAuraRuntime {
    constructor() {
        this.canvas = document.getElementById('c');
        this.ctx = this.canvas.getContext('2d');
        this.effects = [];
        this.config = null;
        this.width = 0;
        this.height = 0;
        this.lastTime = performance.now();
        this.isPaused = false;

        this.setupResize();
        this.setupGlobalControls();
    }

    setupGlobalControls() {
        window.pause = () => {
            this.isPaused = true;
        };
        window.resume = () => {
            if (this.isPaused) {
                this.isPaused = false;
                this.lastTime = performance.now();
                this.animate();
            }
        };
    }

    setupResize() {
        const resize = () => {
            this.width = this.canvas.width = window.innerWidth;
            this.height = this.canvas.height = window.innerHeight;
            this.effects.forEach(e => {
                if (e.resize) e.resize(this.width, this.height);
            });
        };
        window.addEventListener('resize', resize);
        resize();
    }

    init(definition) {
        this.config = definition;
        this.effects = [];

        if (definition.effects && Array.isArray(definition.effects)) {
            definition.effects.forEach(effConfig => {
                if (effConfig.enabled !== false) {
                    const effectInstance = EffectRegistry.create(effConfig.type, effConfig.parameters || {});
                    if (effectInstance) {
                        if (effectInstance.resize) effectInstance.resize(this.width, this.height);
                        this.effects.push(effectInstance);
                    }
                }
            });
        }

        if (window.macAura) {
            window.macAura.onInit(config => this.updateSettings(config ? config.settings : null));
            window.macAura.onUpdate(state => {
                this.updateAudioState(state);
                if (state && state.settings) this.updateSettings(state.settings);
            });
        }

        this.animate();
    }

    updateSettings(settings) {
        if (!settings) return;
        Object.keys(settings).forEach(key => {
            const val = settings[key];
            const parts = key.split('.');
            if (parts.length === 2) {
                const [effectType, paramName] = parts;
                this.effects.forEach(e => {
                    if (e.type === effectType) {
                        if (!e.baseParameters) e.baseParameters = {};
                        e.baseParameters[paramName] = val;
                        if (!e.parameters) e.parameters = {};
                        e.parameters[paramName] = val;
                        if (typeof e.onParameterChange === 'function') {
                            e.onParameterChange(paramName, val);
                        }
                    }
                });
            }
        });
    }

    updateAudioState(state) {
        if (!this.config || !this.config.audio_mappings || !Array.isArray(this.config.audio_mappings)) return;

        const audio = state.audio || {};
        this.config.audio_mappings.forEach(mapping => {
            let value = 0;
            if (mapping.source === 'bass') value = audio.bass || 0;
            else if (mapping.source === 'mid') value = audio.mid || 0;
            else if (mapping.source === 'treble') value = audio.treble || 0;
            else if (mapping.source === 'energy') value = audio.energy || 0;

            const targetParts = mapping.target.split('.');
            if (targetParts.length === 2) {
                const [effectType, paramName] = targetParts;
                this.effects.forEach(e => {
                    if (e.type === effectType && e.parameters) {
                        const baseVal = e.baseParameters ? (parseFloat(e.baseParameters[paramName]) || 0) : 0;
                        const finalVal = baseVal + value * (mapping.multiplier || 1.0);
                        e.parameters[paramName] = finalVal;
                        if (paramName === 'density' && typeof e.onParameterChange === 'function') {
                            // Don't re-init on every audio frame for density to avoid stutter
                        }
                    }
                });
            }
        });
    }

    animate() {
        if (this.isPaused) return;

        const now = performance.now();
        const rawDt = (now - this.lastTime) / 1000.0;
        const dt = Math.min(Math.max(rawDt, 0.001), 0.033);
        this.lastTime = now;

        // Render Scene Background
        if (this.config && this.config.background && this.config.background.colors) {
            const colors = this.config.background.colors;
            if (colors.length >= 2) {
                const grad = this.ctx.createLinearGradient(0, 0, 0, this.height);
                grad.addColorStop(0, colors[0]);
                grad.addColorStop(1, colors[1]);
                this.ctx.fillStyle = grad;
            } else {
                this.ctx.fillStyle = colors[0] || '#040711';
            }
        } else {
            this.ctx.fillStyle = '#040711';
        }

        this.ctx.fillRect(0, 0, this.width, this.height);

        // Update and Render Active Effects
        for (let effect of this.effects) {
            effect.update(dt);
            effect.render(this.ctx, this.width, this.height);
        }

        requestAnimationFrame(() => this.animate());
    }
}
