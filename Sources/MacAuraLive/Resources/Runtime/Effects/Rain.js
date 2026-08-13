class RainEffect {
    constructor(parameters = {}) {
        this.type = 'rain';
        this.baseParameters = { ...parameters };
        this.parameters = { ...parameters };
        this.width = window.innerWidth || 1920;
        this.height = window.innerHeight || 1080;
        this.drops = [];
        this.init();
    }

    init() {
        const count = parseInt(this.parameters.density || this.baseParameters.density || 300);
        this.drops = [];
        for (let i = 0; i < count; i++) {
            this.drops.push({
                x: Math.random() * (this.width || 1920),
                y: Math.random() * (this.height || 1080),
                length: Math.random() * 25 + 15,
                speed: Math.random() * 14 + 10,
                alpha: Math.random() * 0.5 + 0.35
            });
        }
    }

    onParameterChange(paramName, value) {
        this.parameters[paramName] = value;
        this.baseParameters[paramName] = value;
        if (paramName === 'density') {
            this.init();
        }
    }

    resize(w, h) {
        this.width = w;
        this.height = h;
    }

    update(dt) {
        const speedMult = parseFloat(this.parameters.speed || this.baseParameters.speed || 1.0);
        const wind = parseFloat(this.parameters.wind || this.baseParameters.wind || 0.3);

        for (let d of this.drops) {
            d.y += d.speed * speedMult;
            d.x -= wind * 5.0;

            if (d.y > (this.height || 1080)) {
                d.y = -d.length;
                d.x = Math.random() * (this.width || 1920);
            }
        }
    }

    render(ctx, w, h) {
        const color = this.parameters.color || this.baseParameters.color || '#78c8ff';
        ctx.lineWidth = parseFloat(this.parameters.width || this.baseParameters.width || 1.8);

        for (let d of this.drops) {
            ctx.strokeStyle = color;
            ctx.globalAlpha = d.alpha * parseFloat(this.parameters.opacity || this.baseParameters.opacity || 1.0);
            ctx.beginPath();
            ctx.moveTo(d.x, d.y);
            ctx.lineTo(d.x - 2, d.y + d.length);
            ctx.stroke();
        }
        ctx.globalAlpha = 1.0;
    }
}

EffectRegistry.register('rain', RainEffect);
