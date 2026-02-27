// If you get no such module 'receive_sharing_intent' error. 
// Go to Build Phases of your Runner target and
// move `Embed Foundation Extension` to the top of `Thin Binary`. 
import receive_sharing_intent

class ShareViewController: RSIShareViewController {
    // Auto-redirect to host app so shared content opens the Flutter app directly (no Post/Cancel UI).
    // Default is true; override and return false only if you need to show the composition UI.
}