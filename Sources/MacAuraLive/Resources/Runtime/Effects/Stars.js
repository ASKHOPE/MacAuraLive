class StarsEffect {
    constructor(parameters = {}) {
        this.type = 'stars';
        this.baseParameters = { ...parameters };
        this.parameters = { ...parameters };
        this.stars = [];
        this.init();
    }

    init() {
        const count = parseInt(this.parameters.density || 350);
        this.stars = [];
        for (let i = 0; i < count; i++) {
            this.stars.push({
                x: (Math.random() - 0.5) * 1920 * 2,
                y: (Math.random() - 0.5) * 1080 * 2,
                z: Math.random() * 1920
            });
        }
    }

    resize(w, h) {
        this.width = w;
        this.height = h;
    }

    update(dt) {
        const speed = parseFloat(this.parameters.speed || 6.0);
        for (let s of this.stars) {
            s.z -= speed;
            if (s.z <= 0) {
                s.z = this.width || 1920;
                s.x = (Math.random() - 0.5) * (this.width || 1920) * 2;
                s.y = (Math.random() - 0.5) * (this.height || 1080) * 2;
            }
        }
    }

    render(ctx, w, h) {
        const cx = w / 2, cy = h / 2;
        ctx.fillStyle = this.parameters.color || '#c8dcff';

        for (let s of this.stars) {
            const k = 250 / s.z;
            const px = s.x * k + cx;
            const py = s.y * k + cy;

            if (px >= 0 && px <= w && py >= 0 && py <= h) {
                const size = Math.max(0.5, (1 - s.z / w) * 3);
                ctx.globalAlpha = 1 - s.z / w;
                ctx.beginPath();
                ctx.arc(px, py, size, 0, Math.PI * 2);
                ctx.fill();
            }
        }
        ctx.globalAlpha = 1.0;
    }
}

EffectRegistry.register('stars', StarsEffect);
